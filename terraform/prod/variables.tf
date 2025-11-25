# ========================================
# Production Environment Variables
# ========================================
# Subnet configurations, EC2 instance types, and resource naming for prod environment

variable "subnet_config" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
    name              = string
  }))
  default = {
    "us-east-2a" = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-2a"
      name              = "nat"
    }
    "us-east-2b" = {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-east-2b"
      name              = "nat"
    }
  }
}

variable "private_subnet_config" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
    name              = string
  }))
  default = {
    "jenkins-2a" = {
      cidr_block        = "10.0.3.0/24"
      availability_zone = "us-east-2a"
      name              = "jenkins"
    }
    "jenkins-2b" = {
      cidr_block        = "10.0.4.0/24"
      availability_zone = "us-east-2b"
      name              = "jenkins"
    }
    "eks-2a" = {
      cidr_block        = "10.0.5.0/24"
      availability_zone = "us-east-2a"
      name              = "eks"
    }
    "eks-2b" = {
      cidr_block        = "10.0.6.0/24"
      availability_zone = "us-east-2b"
      name              = "eks"
    }
    "rds-2a" = {
      cidr_block        = "10.0.7.0/24"
      availability_zone = "us-east-2a"
      name              = "rds"
    }
    "rds-2b" = {
      cidr_block        = "10.0.8.0/24"
      availability_zone = "us-east-2b"
      name              = "rds"
    }
  }
}

variable "ec2_config" {
  type = map(object({
    instance_type     = string
    availability_zone = string
    tags              = map(string)
  }))
  default = {
    "jenkins-2a" = {
      instance_type     = "t3.medium"
      availability_zone = "us-east-2a"
      tags              = { Name = "jenkins_main" }
    }
    # Removed jenkins-2b - using EKS pods for Jenkins agents
  }
}
