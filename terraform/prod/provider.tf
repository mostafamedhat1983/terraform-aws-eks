# ========================================
# Terraform & Provider Configuration
# ========================================
# AWS provider v5.x pinned for stability

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

# Default tags applied to all resources for governance and cost tracking
provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      Environment = "prod"
      Project     = "platform"
      ManagedBy   = "terraform"
      Owner       = "Mostafa"
    }
  }
}

# Helm provider for Kubernetes package management
# Note: Helm provider configuration depends on EKS cluster existing
# If cluster doesn't exist yet, Helm operations will be skipped
provider "helm" {
  kubernetes {
    host                   = try(module.eks.cluster_endpoint, "")
    cluster_ca_certificate = try(base64decode(module.eks.cluster_certificate_authority_data), "")
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        try(module.eks.cluster_name, "dummy")
      ]
    }
  }
}