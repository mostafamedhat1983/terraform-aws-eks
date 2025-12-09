variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "Map of public subnet configurations"
  type = map(object({
    cidr_block        = string
    availability_zone = string
    name              = string
  }))
}

variable "private_subnets" {
  description = "Map of private subnet configurations"
  type = map(object({
    cidr_block        = string
    availability_zone = string
    name              = string
  }))
}

variable "cluster_name" {
  description = "Name of the EKS cluster (for subnet tagging)"
  type        = string
}

variable "igw_name" {
  description = "Name of the Internet Gateway"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/prod) for resource naming"
  type        = string
}

variable "eks_cluster_security_group_id" {
  description = "Security group ID of the EKS cluster for RDS access"
  type        = string
  default     = ""
}