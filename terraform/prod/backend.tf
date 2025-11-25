# ========================================
# Terraform State Backend
# ========================================
# S3 backend with native locking (2024 feature - replaces DynamoDB)

terraform {
  backend "s3" {
    bucket       = "prod-backend-5867"
    key          = "prod/tf-state/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true  # S3 native locking
  }
}