# IAM Role Module

Creates IAM role with instance profile and attaches specified policies. Supports multiple AWS services (EC2, EKS, etc.).

## Usage

### For EC2 (Jenkins)
```hcl
module "jenkins_role" {
  source = "../modules/role"
  
  name = "ec2-ssm-ecr-role"
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  ]
  # service defaults to "ec2.amazonaws.com"
}
```

### For EKS Cluster
```hcl
module "eks_cluster_role" {
  source = "../modules/role"
  
  name    = "EKS-cluster-role"
  service = "eks.amazonaws.com"
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  ]
}
```

### For EKS Pod Identity (EBS CSI Driver)
```hcl
module "ebs_csi_driver_role" {
  source = "../modules/role"
  
  name    = "ebs-csi-driver-role"
  service = "pods.eks.amazonaws.com"
  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | The name of the IAM role | `string` | n/a | yes |
| policy_arns | List of IAM policy ARNs to attach | `list(string)` | n/a | yes |
| service | The service that will assume this role | `string` | `"ec2.amazonaws.com"` | no |

## Outputs

| Name | Description |
|------|-------------|
| role_id | The ID of the IAM role |
| role_arn | The ARN of the IAM role |
| instance_profile_name | The name of the instance profile |

## Supported Services

- `ec2.amazonaws.com` (default) - For EC2 instances
- `eks.amazonaws.com` - For EKS clusters
- `pods.eks.amazonaws.com` - For EKS Pod Identity (automatically includes `sts:TagSession` action)
- Any AWS service principal

## Features

- Flexible service principal support
- Automatic instance profile creation for EC2
- Automatic `sts:TagSession` action for Pod Identity
- Supports multiple policy attachments
- Follows least privilege principle
