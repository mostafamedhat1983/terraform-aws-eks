# ========================================
# VPC
# ========================================
# Virtual Private Cloud for all infrastructure
# Isolated network environment for EKS, RDS, and EC2

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = var.vpc_name
  }
}

# ========================================
# Public Subnets
# ========================================
# Subnets with internet access via Internet Gateway
# Used for: NAT Gateways

resource "aws_subnet" "public" {
  for_each = var.public_subnets
  vpc_id     = aws_vpc.this.id
  cidr_block = each.value.cidr_block
  availability_zone = each.value.availability_zone
  map_public_ip_on_launch = true
  tags = merge(
    {
      Name = each.value.name
    },
    {
      "kubernetes.io/role/elb" = "1"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )
}

# ========================================
# Private Subnets
# ========================================
# Subnets without direct internet access
# Internet access via NAT Gateway
# Used for: Jenkins EC2, EKS nodes, RDS

resource "aws_subnet" "private" {
  for_each = var.private_subnets
  vpc_id     = aws_vpc.this.id
  cidr_block = each.value.cidr_block
  availability_zone = each.value.availability_zone
  map_public_ip_on_launch = false
  tags = merge(
    {
      Name = each.value.name
    },
    {
      "kubernetes.io/role/internal-elb" = "1"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )
}

# ========================================
# Internet Gateway
# ========================================
# Provides internet access for public subnets
# Used by NAT Gateways for outbound traffic

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = var.igw_name
  }
}

# ========================================
# NAT Gateway Configuration
# ========================================
# Dev: 1 NAT Gateway (cost optimization ~$35/month savings)
# Prod: 2 NAT Gateways (high availability across AZs)

# Dynamic subnet selection: Pick first subnet if count=1, otherwise use all
locals {
  nat_subnets = var.nat_gateway_count == 1 ? {
    for k, v in var.public_subnets : k => v if k == keys(var.public_subnets)[0]
  } : var.public_subnets
  
  # Cache first NAT key for dev routing (all traffic through one NAT)
  first_nat_key = keys(local.nat_subnets)[0]
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  for_each = local.nat_subnets
  domain   = "vpc"
  tags = {
    Name = "${each.value.name}-${each.key}-eip"
  }
}

# NAT Gateways for outbound internet access from private subnets
resource "aws_nat_gateway" "this" {
  for_each      = local.nat_subnets
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name = "${each.value.name}-${each.key}-nat"
  }
}

# ========================================
# Public Route Tables
# ========================================
# Routes traffic from public subnets to Internet Gateway

resource "aws_route_table" "public" {
  for_each = var.public_subnets
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${each.value.name}-${each.key}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each = var.public_subnets
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[each.key].id
}

# ========================================
# Private Route Tables
# ========================================
# Routes traffic from private subnets to NAT Gateway
# Dev: All subnets use single NAT
# Prod: Each AZ uses its own NAT

resource "aws_route_table" "private" {
  for_each = var.private_subnets
  vpc_id   = aws_vpc.this.id

  # Conditional routing: Single NAT (dev) vs per-AZ NAT (prod)
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.nat_gateway_count == 1 ? aws_nat_gateway.this[local.first_nat_key].id : aws_nat_gateway.this[each.value.availability_zone].id
  }

  tags = {
    Name = "${each.value.name}-${each.key}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  for_each = var.private_subnets
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

# ========================================
# Jenkins Security Group
# ========================================
# Controls network access for Jenkins EC2 instances
# Allows: Agent communication (port 50000), EKS API access (443)

resource "aws_security_group" "jenkins" {
  name        = "${var.environment}-jenkins-sg"
  description = "Security group for Jenkins instances"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.environment}-jenkins-sg"
  }
}

# Jenkins web UI and WebSocket (for Kubernetes plugin)
resource "aws_security_group_rule" "jenkins_web" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = var.eks_cluster_security_group_id
  security_group_id        = aws_security_group.jenkins.id
  description              = "Jenkins web UI from EKS cluster"
}

# Jenkins agent communication (controller <-> agents in EKS)
resource "aws_security_group_rule" "jenkins_agent" {
  type                     = "ingress"
  from_port                = 50000
  to_port                  = 50000
  protocol                 = "tcp"
  source_security_group_id = var.eks_cluster_security_group_id
  security_group_id        = aws_security_group.jenkins.id
  description              = "Jenkins agent communication from EKS cluster"
}

# Allow Jenkins to reach internet (package updates, Git, ECR, etc.)
resource "aws_security_group_rule" "jenkins_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jenkins.id
  description       = "Allow all outbound traffic"
}

# ========================================
# RDS Security Group
# ========================================
# Controls database access
# Only allows connections from EKS cluster security group

resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.environment}-rds-sg"
  }
}

# Allow MySQL connections from EKS pods only
resource "aws_security_group_rule" "rds_from_eks" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = var.eks_cluster_security_group_id
  security_group_id        = aws_security_group.rds.id
  description              = "MySQL access from EKS cluster"
}

# ========================================
# EKS Control Plane Access
# ========================================
# Allow Jenkins to access EKS API for kubectl commands

resource "aws_security_group_rule" "eks_from_jenkins" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.jenkins.id
  security_group_id        = var.eks_cluster_security_group_id
  description              = "Allow Jenkins to access EKS API"
}



# ========================================
# VPC Endpoint Security Group
# ========================================
# For future VPC endpoints (S3, ECR, Secrets Manager, etc.)
# Currently not deployed to save costs

resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.environment}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.environment}-vpc-endpoints-sg"
  }
}

# Allow HTTPS traffic from VPC to endpoints
resource "aws_security_group_rule" "vpc_endpoints_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr_block]
  security_group_id = aws_security_group.vpc_endpoints.id
  description       = "HTTPS from VPC"
}