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
# Primary use: Stateful applications requiring persistent storage
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
# Chatbot Backend Application
# ========================================
# IAM resources for chatbot backend pods to access AWS services
# Backend requires: AWS Bedrock for AI model inference, Secrets Manager for DB credentials

# ========================================
# Chatbot Backend - IAM Policy
# ========================================
# Allows backend pods to invoke AWS Bedrock models
# Scoped to specific model: deepseek.v3-v1:0

resource "aws_iam_policy" "chatbot_backend_bedrock" {
  name        = "${var.cluster_name}-chatbot-backend-bedrock"
  description = "Policy for chatbot backend to access AWS Bedrock"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InvokeBedrock"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = "arn:aws:bedrock:us-east-2::foundation-model/deepseek.v3-v1:0"
      }
    ]
  })
}

# ========================================
# Chatbot Backend - Secrets Manager IAM Policy
# ========================================
# Allows backend pods to read database credentials from Secrets Manager
# Scoped to specific secret: platform-db-{env}-credentials

resource "aws_iam_policy" "chatbot_backend_secrets" {
  name        = "${var.cluster_name}-chatbot-backend-secrets"
  description = "Policy for chatbot backend to access Secrets Manager"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:us-east-2:*:secret:platform-db-*"
      }
    ]
  })
}

# ========================================
# Chatbot Backend - IAM Role
# ========================================
# IAM role for chatbot backend pods using Pod Identity
# Reuses role module for consistency

module "chatbot_backend_role" {
  source = "../role"
  
  name    = "${var.cluster_name}-chatbot-backend"
  service = "pods.eks.amazonaws.com"
  
  policy_arns = [
    aws_iam_policy.chatbot_backend_bedrock.arn,
    aws_iam_policy.chatbot_backend_secrets.arn
  ]
}

# ========================================
# Chatbot Backend - Pod Identity Association
# ========================================
# Links IAM role to chatbot backend service account
# Enables backend pods to assume IAM role for AWS Bedrock access
# Must match namespace where chatbot is deployed

resource "aws_eks_pod_identity_association" "chatbot_backend" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = var.chatbot_namespace
  service_account = "chatbot-backend-service-account"
  role_arn        = module.chatbot_backend_role.role_arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    module.chatbot_backend_role
  ]
}

# ========================================
# AWS Load Balancer Controller
# ========================================
# Enables automatic ALB/NLB provisioning for Kubernetes Ingress resources
# Authentication: Pod Identity (modern approach, no OIDC needed)

# Download official IAM policy from AWS GitHub
data "http" "aws_load_balancer_controller_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json"
}

# Create IAM policy for AWS Load Balancer Controller
resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "${var.cluster_name}-aws-load-balancer-controller"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = data.http.aws_load_balancer_controller_policy.response_body
}

# IAM role for AWS Load Balancer Controller using Pod Identity
module "aws_load_balancer_controller_role" {
  source = "../role"
  
  name    = "${var.cluster_name}-aws-load-balancer-controller"
  service = "pods.eks.amazonaws.com"
  
  policy_arns = [
    aws_iam_policy.aws_load_balancer_controller.arn
  ]
}

# Link IAM role to AWS Load Balancer Controller service account
resource "aws_eks_pod_identity_association" "aws_load_balancer_controller" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = module.aws_load_balancer_controller_role.role_arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    module.aws_load_balancer_controller_role
  ]
}

# NOTE: AWS Load Balancer Controller installation removed from Terraform to avoid circular dependency
# Install manually after cluster creation using:
# helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
#   -n kube-system \
#   --set clusterName=platform-dev \
#   --set vpcId=<vpc-id> \
#   --set serviceAccount.create=true \
#   --set serviceAccount.name=aws-load-balancer-controller

# ========================================
# Jenkins CI/CD Pipeline
# ========================================
# IAM resources for Jenkins pipeline pods to push Docker images to ECR
# Jenkins pods use jenkins-sa service account in default namespace

# IAM role for Jenkins pipeline pods using Pod Identity
module "jenkins_pipeline_role" {
  source = "../role"
  
  name    = "${var.cluster_name}-jenkins-pipeline"
  service = "pods.eks.amazonaws.com"
  
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  ]
}

# Link IAM role to jenkins-sa service account
resource "aws_eks_pod_identity_association" "jenkins_pipeline" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "default"
  service_account = "jenkins-sa"
  role_arn        = module.jenkins_pipeline_role.role_arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    module.jenkins_pipeline_role
  ]
}