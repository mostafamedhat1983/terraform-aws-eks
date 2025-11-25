# Cost Breakdown

Detailed cost analysis for both development and production environments.

## Development Environment (~$165/month)

| Service | Config | Cost |
|---------|--------|------|
| NAT Gateway | 1x | ~$35 |
| EC2 (Jenkins) | 1x t3.medium | ~$30 |
| RDS MySQL | db.t3.micro, single-AZ, 20GB | ~$15 |
| EKS Control Plane | 1 cluster | $73 |
| EKS Workers | 2x t3.small | ~$30 |

**Total: ~$165/month** (cost-optimized for learning)

## Production Environment (~$310/month)

| Service | Config | Cost |
|---------|--------|------|
| NAT Gateway | 2x (HA) | ~$70 |
| EC2 (Jenkins) | 1x t3.medium | ~$30 |
| RDS MySQL | db.t3.small, Multi-AZ, 50GB | ~$50 |
| EKS Control Plane | 1 cluster | $73 |
| EKS Workers | 3x t3.medium | ~$90 |

**Total: ~$310/month** (high availability and performance)

## Cost Analysis

**Difference:** +$145/month for HA NAT, larger instances, Multi-AZ RDS, more EKS capacity.

**Savings:** Removed second Jenkins EC2 instance (~$15/month dev, ~$30/month prod) by using EKS pods for Jenkins agents.

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
