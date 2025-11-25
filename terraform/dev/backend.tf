# ========================================
# Terraform State Backend
# ========================================
# S3 backend with native locking (2024 feature - replaces DynamoDB)

terraform {
  backend "s3" {
    bucket       = "dev-backend-5867"
    key          = "dev/tf-state/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true  # S3 native locking
  }
}
