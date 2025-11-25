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
  }
}

# Default tags applied to all resources for governance and cost tracking
provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "platform"
      ManagedBy   = "terraform"
      Owner       = "Mostafa"
    }
  }
}