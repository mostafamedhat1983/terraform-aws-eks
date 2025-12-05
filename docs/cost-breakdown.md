# Cost Breakdown

Detailed cost analysis for both development and production environments. All pricing based on **us-east-2 region (2025)**.

## Development Environment (~$177/month)

| Service | Config | Cost |
|---------|--------|------|
| NAT Gateway | 1x | ~$33 |
| EC2 (Jenkins) | 1x t3.medium | ~$30 |
| RDS MySQL | db.t3.micro, single-AZ, 20GB | ~$12 |
| EKS Control Plane | 1 cluster | $72 |
| EKS Workers | 3x t3.small | ~$45 |

**Total: ~$192/month** (cost-optimized for learning)

**Cost Breakdown Details:**
- NAT Gateway: $0.045/hour × 730 hours = $32.85/month
- t3.medium EC2: ~$30.37/month (730 hours)
- db.t3.micro RDS: ~$12.41/month
- EKS Control Plane: $0.10/hour × 730 hours = $73/month
- 3x t3.small EKS nodes: ~$15/month each = $45/month

## Production Environment (~$294/month)

| Service | Config | Cost |
|---------|--------|------|
| NAT Gateway | 2x (HA) | ~$66 |
| EC2 (Jenkins) | 1x t3.medium | ~$30 |
| RDS MySQL | db.t3.small, Multi-AZ, 50GB | ~$37 |
| EKS Control Plane | 1 cluster | $72 |
| EKS Workers | 3x t3.medium | ~$90 |

**Total: ~$294/month** (high availability and performance)

**Cost Breakdown Details:**
- 2x NAT Gateway (HA): $32.85 × 2 = $65.70/month
- t3.medium EC2: ~$30.37/month
- db.t3.small Multi-AZ RDS: ~$36.50/month (base price doubled for Multi-AZ)
- EKS Control Plane: $0.10/hour × 730 hours = $73/month
- 3x t3.medium EKS nodes: ~$30/month each = $90/month

## Cost Analysis

**Difference:** +$102/month for production includes:
- HA NAT Gateways: +$33/month (1 → 2 gateways)
- Multi-AZ RDS: +$25/month (single-AZ → Multi-AZ with larger instance)
- Increased EKS capacity: +$45/month (3x t3.small → 3x t3.medium)

**Savings:** Removed second Jenkins EC2 instance (~$15/month dev, ~$30/month prod) by using EKS pods for Jenkins agents.

**Additional Costs Not Included:**
- Data transfer charges (typically minimal for internal traffic)
- EBS snapshots and backups (S3 storage costs)
- CloudWatch logs retention
- AWS Secrets Manager: ~$0.40/month per secret
- ECR storage: First 500MB free, then $0.10/GB/month

## Cost Optimization Decisions

### Development
- Single NAT Gateway (acceptable risk for non-production)
- Smaller instance types
- Single-AZ RDS
- Minimal EKS node capacity

### Production
- Dual NAT Gateways for high availability
- Larger instance types for better performance
- Multi-AZ RDS with extended backups
- Additional EKS capacity for scaling
