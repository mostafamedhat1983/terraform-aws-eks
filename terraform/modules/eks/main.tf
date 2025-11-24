# ========================================
# Data Sources
# ========================================
# AWS account information for KMS key policy

data "aws_caller_identity" "this" {}

# ========================================
# KMS Encryption
# ========================================
# KMS key for encrypting EKS cluster secrets (Kubernetes secrets at rest)
# Key rotation enabled for security compliance

resource "aws_kms_key" "this" {
  description             = "EKS cluster encryption key"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "Enable IAM User Permissions"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.this.account_id}:root"
      }
      Action   = "kms:*"
      Resource = "*"
    }]
  })
}

# User-friendly alias for KMS key
resource "aws_kms_alias" "this" {
  name          = "alias/eks-cluster-key-${var.cluster_name}"
  target_key_id = aws_kms_key.this.key_id
}

# ========================================
# EKS Cluster
# ========================================
# Core EKS cluster configuration
# - Private API endpoint (accessed via Jenkins EC2 using SSM)
# - Control plane logging enabled (api, audit, authenticator)
# - Secrets encrypted with KMS
# - API authentication mode for Jenkins access (replaces aws-auth ConfigMap)

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.cluster_version

  # CloudWatch logging for security and troubleshooting
  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  # Modern access entry API (not aws-auth ConfigMap)
  access_config {
    authentication_mode = "API"
  }

  # Network configuration
  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
  }

  # Kubernetes secrets encryption at rest
  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.this.arn
    }
  }
}

# ========================================
# EKS Node Group
# ========================================
# Managed node group for running workloads
# Autoscaling configured via min/max/desired size
# Dev: 2x t3.small (min: 1, max: 3)
# Prod: 3x t3.medium (min: 2, max: 5)

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.node_group_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  instance_types = var.instance_types
  disk_size      = var.disk_size

  # Rolling update configuration
  update_config {
    max_unavailable = 1
  }
}
# ========================================
# Jenkins Access Configuration
# ========================================
# Grants Jenkins EC2 instance admin access to EKS cluster
# Uses modern Access Entry API (not aws-auth ConfigMap)

resource "aws_eks_access_entry" "jenkins" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.jenkins_role_arn
  type          = "STANDARD"
}

# Associate cluster admin policy with Jenkins role
resource "aws_eks_access_policy_association" "jenkins" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.jenkins_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.jenkins]
}

# ========================================
# Pod Identity Agent
# ========================================
# Foundational addon that enables EKS Pod Identity authentication
# Required by: EBS CSI Driver, Secrets Store CSI Driver (future)
# Replaces legacy OIDC/IRSA authentication method

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "eks-pod-identity-agent"
}

# ========================================
# EBS CSI Driver
# ========================================
# Provides persistent storage capabilities using EBS volumes
# Primary use: Jenkins agent workspaces, future stateful applications
# Authentication: Pod Identity (modern approach, no OIDC needed)

# IAM role for EBS CSI Driver using Pod Identity
module "ebs_csi_driver_role" {
  source = "../role"
  
  name    = "${var.cluster_name}-ebs-csi-driver"
  service = "pods.eks.amazonaws.com"
  
  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  ]
}

# Link IAM role to EBS CSI Driver service account
resource "aws_eks_pod_identity_association" "ebs_csi_driver" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"
  role_arn        = module.ebs_csi_driver_role.role_arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    module.ebs_csi_driver_role
  ]
}

# Install EBS CSI Driver addon
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "aws-ebs-csi-driver"
  
  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_eks_pod_identity_association.ebs_csi_driver
  ]
}

# ========================================
# AWS Secrets Store CSI Driver
# ========================================
# Enables pods to mount secrets from AWS Secrets Manager as files
# Primary use: Application secrets (database credentials, API keys)
# Authentication: Pod Identity (modern approach, no OIDC needed)

# Install Secrets Store CSI Driver addon
resource "aws_eks_addon" "secrets_store_csi_driver" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "aws-secrets-store-csi-driver-provider"

  depends_on = [
    aws_eks_addon.pod_identity_agent
  ]
}

# ========================================
# Secrets Store CSI Driver - IAM Policy
# ========================================
# Defines permissions for CSI driver to access Secrets Manager
# Environment-scoped: dev can only access *-dev-* secrets, prod only *-prod-*

resource "aws_iam_policy" "secrets_store_csi" {
  name        = "${var.cluster_name}-secrets-store-csi-policy"
  description = "Policy for Secrets Store CSI Driver to access ${var.environment} secrets"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GetSecretValue"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        # Environment-specific wildcard: *-{environment}-*
        # Dev example: platform-db-dev-credentials, chatbot-api-dev-keys
        # Prod example: platform-db-prod-credentials, chatbot-api-prod-keys
        Resource = [
          "arn:aws:secretsmanager:*:${data.aws_caller_identity.this.account_id}:secret:platform-*-${var.environment}-*",
          "arn:aws:secretsmanager:*:${data.aws_caller_identity.this.account_id}:secret:chatbot-*-${var.environment}-*",
          "arn:aws:secretsmanager:*:${data.aws_caller_identity.this.account_id}:secret:monitoring-*-${var.environment}-*"
        ]
      },
      {
        Sid      = "ListSecrets"
        Effect   = "Allow"
        Action   = "secretsmanager:ListSecrets"
        Resource = "*"
      }
    ]
  })
}

# ========================================
# Secrets Store CSI Driver - IAM Role
# ========================================
# IAM role for Secrets Store CSI Driver using Pod Identity
# Reuses role module for consistency with EBS CSI Driver

module "secrets_store_csi_role" {
  source = "../role"
  
  name    = "${var.cluster_name}-secrets-store-csi"
  service = "pods.eks.amazonaws.com"
  
  policy_arns = [
    aws_iam_policy.secrets_store_csi.arn
  ]
}

# ========================================
# Secrets Store CSI Driver - Pod Identity Association
# ========================================
# Links IAM role to Secrets Store CSI Driver service account
# Enables CSI driver pods to assume the IAM role for AWS access

resource "aws_eks_pod_identity_association" "secrets_store_csi" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "kube-system"
  service_account = "secrets-store-csi-driver-provider-aws"
  role_arn        = module.secrets_store_csi_role.role_arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    module.secrets_store_csi_role,
    aws_eks_addon.secrets_store_csi_driver
  ]
}