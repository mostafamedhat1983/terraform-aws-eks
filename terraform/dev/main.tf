data "aws_ami" "jenkins" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["jenkins-*"]
  }
}

module "network" {
  source = "../modules/network"

  vpc_name       = "vpc-dev"
  vpc_cidr_block = "10.0.0.0/16"
  environment    = "dev"

  public_subnets  = var.subnet_config
  private_subnets = var.private_subnet_config

  igw_name                       = "igw-dev"
  nat_gateway_count              = 1
  eks_cluster_security_group_id  = module.eks.cluster_security_group_id
}

module "ec2" {
  source                 = "../modules/ec2"
  for_each               = var.ec2_config
  ami                    = data.aws_ami.jenkins.id
  instance_type          = each.value.instance_type
  availability_zone      = each.value.availability_zone
  subnet_id              = module.network.private_subnet_ids[each.key]
  vpc_security_group_ids = [module.network.jenkins_sg_id]
  tags                   = each.value.tags
  iam_instance_profile   = module.jenkins_role.instance_profile_name
}

resource "aws_iam_policy" "jenkins_eks" {
  name        = "jenkins-eks-access-dev"
  description = "Allow Jenkins to describe EKS clusters for deployment"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["eks:DescribeCluster"]
      Resource = module.eks.cluster_arn
    }]
  })
}

resource "aws_iam_policy" "jenkins_bedrock" {
  name        = "jenkins-bedrock-access-dev"
  description = "Allow Jenkins to invoke AWS Bedrock models for chatbot deployment"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["bedrock:InvokeModel"]
      Resource = "arn:aws:bedrock:us-east-2::foundation-model/us.anthropic.claude-3-haiku-20240307-v1:0"
    }]
  })
}

module "jenkins_role" {
  source = "../modules/role"
  name   = "ec2-ssm-ecr-role-dev"
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser",
    aws_iam_policy.jenkins_eks.arn,
    aws_iam_policy.jenkins_bedrock.arn
  ]
}

module "eks_cluster_role" {
  source = "../modules/role"
  name   = "EKS-cluster-role-dev"
  service = "eks.amazonaws.com"
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  ]
}

module "eks_node_role" {
  source = "../modules/role"
  name   = "EKS-node-role-dev"
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ]
}

module "rds" {
  source = "../modules/rds"

  identifier           = "platform-db-dev"
  db_subnet_group_name = "platform-db-subnet-group-dev"
  secret_name          = "platform-db-dev-credentials"

  subnet_ids = [
    module.network.private_subnet_ids["rds-2a"],
    module.network.private_subnet_ids["rds-2b"]
  ]

  vpc_security_group_ids = [module.network.rds_sg_id]

  storage_size   = 20
  storage_type   = "gp3"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  multi_az                = false
  backup_retention_period = 1
  skip_final_snapshot     = true

  tags = {
    Name = "platform-db-dev"
  }
}

module "eks" {
  source = "../modules/eks"

  cluster_name        = "platform-dev"
  cluster_role_arn    = module.eks_cluster_role.role_arn
  node_role_arn       = module.eks_node_role.role_arn
  jenkins_role_arn    = module.jenkins_role.role_arn
  cluster_version     = "1.34"
  
  subnet_ids = [
    module.network.private_subnet_ids["eks-2a"],
    module.network.private_subnet_ids["eks-2b"]
  ]

  endpoint_private_access = true
  endpoint_public_access  = false

  node_group_name    = "platform-dev-nodes"
  node_desired_size  = 2
  node_max_size      = 3
  node_min_size      = 1
  instance_types     = ["t3.small"]
  disk_size          = 20
}
