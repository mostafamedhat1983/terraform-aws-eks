# Cost Breakdown

Detailed cost analysis for both development and production environments. All pricing based on **us-east-2 region (2025)**.

## Development Environment (~$207/month)

| Service | Config | Cost |
|---------|--------|------|
| Regional NAT Gateway | 1x (HA across all AZs) | ~$33 |
| EC2 (Jenkins) | 1x t3.medium | ~$30 |
| RDS MySQL | db.t3.micro, single-AZ, 20GB | ~$12 |
| EKS Control Plane | 1 cluster | $72 |
| EKS Workers | 4x t3.small (44 pods capacity) | ~$60 |

**Total: ~$207/month** (cost-optimized for learning)

**Cost Breakdown Details:**
- Regional NAT Gateway: $0.045/hour × 730 hours = $32.85/month
- t3.medium EC2: ~$30.37/month (730 hours)
- db.t3.micro RDS: ~$12.41/month
- EKS Control Plane: $0.10/hour × 730 hours = $73/month
- 4x t3.small EKS nodes: ~$15/month each = $60/month

## Production Environment (~$289/month)

| Service | Config | Cost |
|---------|--------|------|
| Regional NAT Gateway | 1x (HA across all AZs) | ~$33 |
| EC2 (Jenkins) | 1x t3.medium | ~$30 |
| RDS MySQL | db.t3.small, Multi-AZ, 50GB | ~$37 |
| EKS Control Plane | 1 cluster | $72 |
| EKS Workers | 4x t3.medium (68 pods capacity) | ~$120 |

**Total: ~$289/month** (high availability and performance)

**Cost Breakdown Details:**
- Regional NAT Gateway: $0.045/hour × 730 hours = $32.85/month (saves $33/month vs 2 zonal NATs)
- t3.medium EC2: ~$30.37/month
- db.t3.small Multi-AZ RDS: ~$36.50/month (base price doubled for Multi-AZ)
- EKS Control Plane: $0.10/hour × 730 hours = $73/month
- 4x t3.medium EKS nodes: ~$30/month each = $120/month

## Cost Analysis

**Difference:** +$82/month for production includes:
- Regional NAT Gateway: $0/month (same cost as dev)
- Multi-AZ RDS: +$25/month (single-AZ → Multi-AZ with larger instance)
- Increased EKS capacity: +$60/month (4x t3.small → 4x t3.medium)

**Node Scaling Rationale:**
- Increased from 3 to 4 nodes per environment to support monitoring stack (Prometheus, Grafana, Falco) + application workloads
- Dev: 44 pods capacity (11 pods per t3.small node)
- Prod: 68 pods capacity (17 pods per t3.medium node)
- Additional node provides better high availability and headroom for Jenkins agents

**Regional NAT Gateway Savings:**
- Dev: Same cost as 1 zonal NAT, but with HA across all AZs
- Prod: Saves ~$33/month compared to 2 zonal NAT Gateways

**Savings:** Removed second Jenkins EC2 instance (~$15/month dev, ~$30/month prod) by using EKS pods for Jenkins agents.

**Additional Costs Not Included:**
- Data transfer charges (typically minimal for internal traffic)
- EBS snapshots and backups (S3 storage costs)
- CloudWatch logs retention
- AWS Secrets Manager: ~$0.40/month per secret
- ECR storage: First 500MB free, then $0.10/GB/month

## Cost Optimization Decisions

### Development
- Regional NAT Gateway (HA across all AZs at single NAT cost)
- Smaller instance types (t3.small nodes)
- Single-AZ RDS
- 4 nodes for adequate pod capacity (44 pods total)

### Production
- Regional NAT Gateway (saves $33/month vs 2 zonal NATs, same HA)
- Larger instance types for better performance (t3.medium nodes)
- Multi-AZ RDS with extended backups
- 4 nodes for high availability and scaling (68 pods total)
