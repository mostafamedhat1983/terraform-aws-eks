# EKS Module

Creates a complete EKS cluster with a managed node group, KMS encryption for secrets, and Jenkins access configuration.

## Usage

```hcl
module "eks" {
  source = "../modules/eks"

  cluster_name     = "todo-app-dev"
  cluster_role_arn = module.eks_cluster_role.role_arn
  node_role_arn    = module.eks_node_role.role_arn
  jenkins_role_arn = module.jenkins_role.role_arn
  cluster_version  = "1.34"
  
  subnet_ids = [
    module.network.private_subnet_ids["eks-2a"],
    module.network.private_subnet_ids["eks-2b"]
  ]
  
  endpoint_private_access = true
  endpoint_public_access  = false
  
  node_group_name   = "todo-app-dev-nodes"
  node_desired_size = 2
  node_max_size     = 3
  node_min_size     = 1
  instance_types    = ["t3.small"]
  disk_size         = 20
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| cluster_role_arn | ARN of the IAM role for EKS cluster | `string` | n/a | yes |
| node_role_arn | ARN of the IAM role for EKS worker nodes | `string` | n/a | yes |
| jenkins_role_arn | ARN of the Jenkins IAM role for EKS access | `string` | n/a | yes |
| cluster_version | Kubernetes version for EKS cluster | `string` | `"1.34"` | no |
| subnet_ids | List of subnet IDs for the EKS cluster | `list(string)` | n/a | yes |
| endpoint_private_access | Enable private API server endpoint | `bool` | `true` | no |
| endpoint_public_access | Enable public API server endpoint | `bool` | `false` | no |
| node_group_name | Name of the EKS node group | `string` | n/a | yes |
| node_desired_size | Desired number of worker nodes | `number` | n/a | yes |
| node_max_size | Maximum number of worker nodes | `number` | n/a | yes |
| node_min_size | Minimum number of worker nodes | `number` | n/a | yes |
| instance_types | List of instance types for worker nodes | `list(string)` | `["t3.medium"]` | no |
| disk_size | Disk size in GB for worker nodes | `number` | `20` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | EKS cluster ID |
| cluster_name | EKS cluster name |
| cluster_endpoint | EKS cluster API endpoint |
| cluster_arn | EKS cluster ARN |
| node_group_id | EKS node group ID |
| node_group_status | EKS node group status |

## Features

- **Security:**
  - KMS encryption for Kubernetes secrets
  - Private API endpoint support
  - Control plane logging to CloudWatch
  - Modern EKS Access Entry API (authentication_mode = "API")

- **High Availability:**
  - Multi-AZ node group deployment
  - Auto-scaling support
  - Configurable min/max/desired capacity

- **Access Management:**
  - Jenkins access via EKS Access Entry
  - No legacy aws-auth ConfigMap needed

- **Storage:**
  - EBS CSI Driver with Pod Identity authentication
  - No OIDC provider required

- **Secrets Management:**
  - AWS Secrets Store CSI Driver with Pod Identity
  - Environment-scoped secret access policies
  - Mount secrets from AWS Secrets Manager as files

- **Monitoring:**
  - CloudWatch logging for API, audit, authenticator

## Resources Created

- EKS Cluster
- EKS Managed Node Group
- KMS key for secrets encryption
- EKS Access Entry for Jenkins
- Pod Identity Agent addon
- EBS CSI Driver role (via role module)
- Pod Identity Association for EBS CSI
- EBS CSI Driver addon
- AWS Secrets Store CSI Driver addon
- Secrets Store CSI Driver role (via role module)
- Pod Identity Association for Secrets Store CSI
- IAM policy for environment-scoped secret access
