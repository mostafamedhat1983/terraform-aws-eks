data "aws_caller_identity" "this" {}

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

resource "aws_kms_alias" "this" {
  name          = "alias/eks-cluster-key"
  target_key_id = aws_kms_key.this.key_id
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.cluster_version

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  access_config {
    authentication_mode = "API"
  }

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.this.arn
    }
  }
}

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

  update_config {
    max_unavailable = 1
  }
}
resource "aws_eks_access_entry" "jenkins" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.jenkins_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "jenkins" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.jenkins_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.jenkins]
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "eks-pod-identity-agent"
}
