# Architecture Decisions

This document explains the key technical decisions made in this infrastructure project.

## NAT Gateway Strategy

**Dev:** 1 NAT in us-east-2a (~$35/month) - acceptable risk for dev

**Prod:** 2 NATs (~$70/month) - high availability, no cross-AZ traffic

## RDS Configuration

**Dev:** Single-AZ, 20GB, 1-day backups, db.t3.micro, skip_final_snapshot

**Prod:** Multi-AZ, 50GB, 7-day backups, db.t3.small, timestamped final snapshots (prevents destroy conflicts)

## EKS Storage & Secrets Management

The cluster includes two CSI drivers using EKS Pod Identity authentication:

**EBS CSI Driver** - Persistent storage capabilities:
- **Jenkins Agent Workspaces:** Persistent filesystem for code checkout, dependency caching, and build artifacts
- **Future-Proofing:** Enables stateful applications (Prometheus, message queues, databases) without infrastructure changes

**AWS Secrets Store CSI Driver** - Secrets management:
- **Application Secrets:** Mount secrets from AWS Secrets Manager as files in pods
- **Database Credentials:** Secure access to RDS credentials without hardcoding
- **Environment-Scoped Access:** IAM policies restrict access to environment-specific secrets (dev/prod)

**Authentication:** Both drivers use EKS Pod Identity with IAM roles created via the role module (`service = "pods.eks.amazonaws.com"`), eliminating OIDC provider complexity.

## EKS Configuration

**Dev:** 2x t3.small nodes (desired: 2, min: 1, max: 3), 20GB disk

**Prod:** 3x t3.medium nodes (desired: 3, min: 2, max: 5), 30GB disk

## Jenkins Architecture

**Single Controller + EKS Agents:**
- 1 Jenkins controller EC2 instance per environment
- Jenkins agents run as ephemeral pods in EKS (using Kubernetes plugin)
- Dynamic scaling based on build demand
- Cost-effective: agents only run when needed

**Why not 2 Jenkins instances?**
Originally deployed 2 EC2 instances (controller + static agent), but switched to EKS-based agents for better resource utilization and modern CI/CD practices.

## SSM Session Manager (No Bastion)

**Benefits:** No SSH keys, no bastion maintenance, CloudWatch logging, IAM-based access, no inbound rules, saves ~$15/month

**Access Jenkins:**
```bash
aws ssm start-session --target <jenkins-instance-id> --region us-east-2
```

**Port Forwarding:**
```bash
aws ssm start-session --target <jenkins-instance-id> \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["8080"],"localPortNumber":["8080"]}' \
  --region us-east-2
```

**Note:** First SSM connection after instance launch typically takes 3-5 minutes. First boot from a new AMI may take up to 30 minutes for initial SSM Agent setup. Subsequent connections are immediate.

## Secrets Management

Manual creation outside Terraform ensures secrets persist across `terraform destroy` and never appear in code or Git.

## Jenkins Per-Environment

**Why:** Complete isolation (dev failures don't affect prod), security (prod credentials isolated), compliance, team autonomy, learning value.

**Alternative:** Single Jenkins in "tools" account deploying to all environments (both approaches valid).

## No .tfvars Files

Separate folders (terraform/dev, terraform/prod) with environment-specific code is simpler for 2 environments. .tfvars makes sense for 5+ identical environments.

## Jenkins IAM Least Privilege

```hcl
Resource = module.eks.cluster_arn  # Only its own cluster, not "*"
```
Prevents accidental access to other clusters, limits blast radius.

## Flexible IAM Role Module

```hcl
service = "ec2.amazonaws.com"  # or "eks.amazonaws.com"
```
Single IAM role module reused for EC2 and EKS by changing the `service` parameter (ec2.amazonaws.com vs eks.amazonaws.com). Follows DRY principle.

## Trivy Scanning: CRITICAL Only

**Decision:** Scan AMIs for CRITICAL vulnerabilities only, not HIGH.

**Why:** Testing showed 100+ HIGH findings, mostly Go toolchain CVEs in upstream packages (kubectl, Helm, Docker CLI) and one non-applicable SCSI driver bug. Scanning HIGH would block every build on upstream issues outside our control.

**Trade-off:** CRITICAL catches actively exploited vulnerabilities while avoiding false-positive build failures from toolchain dependencies.
