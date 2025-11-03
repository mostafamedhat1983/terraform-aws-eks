# Todo App Infrastructure - AWS EKS with Terraform

Production-ready AWS infrastructure built from scratch for deploying a containerized todo application on EKS. Demonstrates real-world DevOps practices, security hardening, and infrastructure as code principles.

## 🎯 Project Overview

Every line of code was written with intention, reviewed, debugged, and improved through multiple iterations. The infrastructure evolved from basic requirements to a secure, scalable, production-ready setup.

## 🏗️ Architecture

Two complete environments:  
**Development**  (~$180/month)  
**Production**  ( ~$340/month).

### Development Environment
**Cost-optimized for learning:**
- **VPC:** 2 AZs, 8 subnets (2 public, 6 private)
- **Compute:** 1x Jenkins Controller EC2 (t2.medium)
- **Database:** RDS MySQL 8.0 (single-AZ, 20GB, encrypted)
- **Kubernetes:** EKS 1.34 with 2x t3.small nodes (20GB disk)
- **Networking:** 1 NAT Gateway
- **Registry:** ECR for Docker images
- **Secrets:** AWS Secrets Manager

### Production Environment
**High availability and performance:**
- **VPC:** Same architecture for consistency
- **Compute:** 1x Jenkins Controller EC2 (t3.medium)
- **Database:** RDS MySQL 8.0 (Multi-AZ, 50GB, 7-day backups, encrypted)
- **Kubernetes:** EKS 1.34 with 3x t3.medium nodes (30GB disk)
- **Networking:** 2 NAT Gateways (one per AZ)
- **Registry:** Shared ECR (different tags per environment)
- **Secrets:** Separate Secrets Manager per environment

## 🛠️ What Makes This Different

**Security Hardening:**
- EBS, RDS, and EKS secrets encryption
- Private EKS endpoint, accessed via Jenkins EC2 using SSM
- EKS audit logging enabled
- Jenkins IAM restricted to specific cluster ARNs (not wildcard)

**Code Quality:**
- Descriptive naming (replaced numeric keys with "jenkins-2a", "eks-2a", "rds-2a")
- Variable documentation for all modules
- Dynamic configuration (removed hardcoded AZs)
- Modular design (network, EC2, RDS, IAM, EKS)

**Modern AWS Features:**
- S3 Native State Locking (2024) - `use_lockfile = true` instead of DynamoDB
- EKS Access Entry API (2023) - `authentication_mode = "API"` instead of aws-auth ConfigMap
- ECR with IAM Authentication - no Docker Hub credentials needed
- Secrets Manager bidirectional integration - Terraform reads and updates secrets
- Flexible IAM Role Module - single module reused for EC2 and EKS by changing `service` parameter

**Intentional Design Decisions:**
- Packer-built AMI for consistency (not AWS "latest" AMI)
- Jenkins admin policy for cluster infrastructure management
- Unrestricted egress (restricting requires $50-100/month VPC endpoints)

## 📁 Project Structure

```
terraform/
├── dev/                  # Development environment
│   ├── main.tf, variables.tf, outputs.tf, provider.tf, backend.tf
├── prod/                 # Production environment (same structure)
└── modules/
    ├── network/          # VPC, subnets, NAT, security groups
    ├── ec2/              # EC2 with encrypted EBS
    ├── rds/              # RDS with Secrets Manager integration
    ├── role/             # Flexible IAM role module
    └── eks/              # Complete EKS setup

packer/
├── jenkins.pkr.hcl       # Packer template for Jenkins AMI
└── ansible/
    └── jenkins-playbook.yml  # Ansible provisioning
```

## 🏗️ AMI Build Pipeline (Packer + Ansible)

**Immutable Infrastructure:**
Jenkins instances use custom AMIs built with Packer and Ansible (not user data scripts) for consistency and speed.

**Build Stack:**
- **Packer:** Automates AMI creation from Amazon Linux 2023
- **Ansible:** Provisions using native modules (dnf, systemd, yum_repository)
- **Trivy:** Vulnerability scanning (fails on HIGH/CRITICAL)

**Installed:** Docker, Java 21 Corretto, Git, Jenkins, kubectl v1.34, Helm, AWS CLI

**Security:** GPG verification for all repos, SSH password auth disabled, installation verification, vulnerability scanning

**Build:**
```bash
cd packer
packer init jenkins.pkr.hcl
packer build jenkins.pkr.hcl
```

**Output:** AMI ID saved to `packer/manifest.json` for Terraform reference

**Benefits:** Consistency (no drift), speed (boot ready-to-use), security (vulnerabilities caught pre-deployment), testability, instant rollback.

## 🔒 Security Scanning

**Trivy Integration:**
AMI builds include automated vulnerability scanning with Trivy v0.67.2.

**Configuration:**
- Scans entire root filesystem
- Fails builds only on CRITICAL severity (production best practice)
- Generates timestamped JSON reports
- 15-minute scan timeout

**Current Status:**
- 0 CRITICAL vulnerabilities ✅
- 113 HIGH in latest versions of kubectl v1.34, Helm v3.16+, Jenkins LTS (outdated Go stdlib/Spring dependencies used during compilation - awaiting upstream recompilation)
- 1 HIGH in Amazon Linux kernel (SCSI target module - not used by Jenkins)

**Approach:**
Using latest stable versions of all tools. Vulnerabilities exist in upstream pre-compiled binaries and cannot be fixed without maintainer releases. Following AWS shared responsibility model and pragmatic risk management - tracked but don't block builds.

## 🔐 Security Features

- ✅ All data encrypted at rest (EBS, RDS, EKS secrets, S3)
- ✅ IAM roles with least privilege (no hardcoded credentials)
- ✅ Private subnets for all workloads
- ✅ Security groups with specific rules (no 0.0.0.0/0 ingress)
- ✅ EKS control plane logging to CloudWatch
- ✅ SSM Session Manager (no bastion host or SSH keys)
- ✅ Secrets Manager for database credentials
- ✅ KMS key rotation enabled for EKS secrets encryption
- ✅ S3 state versioning enabled

**Zero Secret Exposure:**
- RDS credentials in Secrets Manager (encrypted with KMS)
- Secrets created manually outside Terraform
- Terraform reads via `data` source (no plaintext)
- Passwords never in Git, code, state files, logs, or images
- S3 versioning + native locking + encryption for state files

**Network Security:**
- All workloads in private subnets
- RDS not publicly accessible
- EKS API endpoint private-only
- NAT Gateway for controlled outbound access

## 💡 Key Technical Decisions

### NAT Gateway Strategy
**Dev:** 1 NAT in us-east-2a (~$35/month) - acceptable risk for dev

**Prod:** 2 NATs (~$70/month) - high availability, no cross-AZ traffic

### RDS Configuration
**Dev:** Single-AZ, 20GB, 1-day backups, db.t3.micro, skip_final_snapshot

**Prod:** Multi-AZ, 50GB, 7-day backups, db.t3.small, final snapshot enabled

### EKS Configuration
**Dev:** 2x t3.small nodes (desired: 2, min: 1, max: 3), 20GB disk

**Prod:** 3x t3.medium nodes (desired: 3, min: 2, max: 5), 30GB disk

### Jenkins Architecture
**Single Controller + EKS Agents:**
- 1 Jenkins controller EC2 instance per environment
- Jenkins agents run as ephemeral pods in EKS (using Kubernetes plugin)
- Dynamic scaling based on build demand
- Cost-effective: agents only run when needed

**Why not 2 Jenkins instances?**
Originally deployed 2 EC2 instances (controller + static agent), but switched to EKS-based agents for better resource utilization and modern CI/CD practices.

### SSM Session Manager (No Bastion)
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

### Secrets Management
Manual creation outside Terraform ensures secrets persist across `terraform destroy` and never appear in code or Git.

### Jenkins Per-Environment
**Why:** Complete isolation (dev failures don't affect prod), security (prod credentials isolated), compliance, team autonomy, learning value.

**Alternative:** Single Jenkins in "tools" account deploying to all environments (both approaches valid).

### No .tfvars Files
Separate folders (terraform/dev, terraform/prod) with environment-specific code is simpler for 2 environments. .tfvars makes sense for 5+ identical environments.

### Jenkins IAM Least Privilege
```hcl
Resource = module.eks.cluster_arn  # Only its own cluster, not "*"
```
Prevents accidental access to other clusters, limits blast radius.

### Flexible IAM Role Module
```hcl
service = "ec2.amazonaws.com"  # or "eks.amazonaws.com"
```
Single IAM role module reused for EC2 and EKS by changing the `service` parameter (ec2.amazonaws.com vs eks.amazonaws.com). Follows DRY principle.

## 🚀 Deployment

**Prerequisites:** AWS CLI, Terraform >= 1.0, S3 bucket for state, Secrets Manager secrets

**1. Create RDS Secrets:**
```bash
# Dev
aws secretsmanager create-secret \
  --name todo-db-dev-credentials \
  --secret-string '{"username":"admin","password":"YourDevPassword","dbname":"tododb"}' \
  --region us-east-2

# Prod
aws secretsmanager create-secret \
  --name todo-db-prod-credentials \
  --secret-string '{"username":"admin","password":"YourStrongProdPassword","dbname":"tododb"}' \
  --region us-east-2
```

**2. Deploy:**
```bash
cd terraform/dev
terraform init
terraform plan
terraform apply
```

**3. Configure kubectl:**
```bash
aws ssm start-session --target <jenkins-instance-id>
aws eks update-kubeconfig --name todo-app-dev --region us-east-2
```

## 📊 Cost Breakdown

### Development (~$165/month)
| Service | Config | Cost |
|---------|--------|------|
| NAT Gateway | 1x | ~$35 |
| EC2 (Jenkins) | 1x t2.medium | ~$15 |
| RDS MySQL | db.t3.micro, single-AZ, 20GB | ~$15 |
| EKS Control Plane | 1 cluster | $73 |
| EKS Workers | 2x t3.small | ~$30 |

### Production (~$310/month)
| Service | Config | Cost |
|---------|--------|------|
| NAT Gateway | 2x (HA) | ~$70 |
| EC2 (Jenkins) | 1x t3.medium | ~$30 |
| RDS MySQL | db.t3.small, Multi-AZ, 50GB | ~$50 |
| EKS Control Plane | 1 cluster | $73 |
| EKS Workers | 3x t3.medium | ~$90 |

**Difference:** +$145/month for HA NAT, larger instances, Multi-AZ RDS, more EKS capacity.

**Savings:** Removed second Jenkins EC2 instance (~$15/month dev, ~$30/month prod) by using EKS pods for Jenkins agents.

## 🤖 AI-Assisted Development

Built with **Amazon Q** and **Gemini Code Assist** as productivity tools, not code generators.

**AI Used For:** Code review (security issues, best practices), documentation (variable descriptions, README), debugging (Terraform syntax, AWS configs), learning (AWS concepts, patterns).

**AI Didn't Do:** Architecture design, module creation, tradeoff decisions, understanding project context.

**Result:** Saved hours on documentation and debugging, allowing focus on AWS services, design decisions, and real infrastructure problems. Every line reviewed, understood, and intentionally committed.

**Production Creation:** Amazon Q replicated dev to prod by adjusting variables (NAT, RDS, instance sizes) - demonstrating modular design benefits.

**Post-Deployment Review:** After initial completion, Amazon Q performed comprehensive code review and identified 4 integration issues:
1. **Packer-built AMI not integrated** - Terraform was using hardcoded AMI ID instead of automatically using latest Packer build (FIXED)
2. **EKS-RDS connectivity broken** - Security group configuration prevented pods from reaching database (FIXED)
3. **Multi-environment deployment limitation** - Security group names would conflict if dev and prod deployed to same AWS account (FIXED)
4. **NAT Gateway routing logic fragility** - Works correctly but relies on naming conventions (tracked for future improvement)

Critical issues were analyzed, root causes identified, and fixes implemented, demonstrating iterative improvement and the value of thorough code review in catching integration problems before production deployment.

## 🎓 What I Learned

1. Building modular, reusable Terraform modules
2. Encryption, IAM roles, network isolation
3. Strategic cost vs security tradeoffs
4. Deep dive into VPC, EKS, RDS, Secrets Manager, SSM
5. Iterative improvements from code review
6. When to optimize for cost vs security vs simplicity

## 🔄 Project Evolution

**Initial:** Basic VPC/EC2, hardcoded values, missing encryption, public EKS endpoint, numeric keys

**Final:** Modular code, full encryption, secure access, descriptive naming, comprehensive docs, production-ready

## 📝 Lessons Learned

1. Packer-built AMI = consistency and stability
2. Dev environments can make reasonable cost tradeoffs
3. Documentation matters for future-you
4. Modular design saves time and reduces errors
5. Defense in depth: encryption + IAM + network + logging

## 🔮 Future Enhancements

**Already Implemented:**
- ✅ Production with Multi-AZ RDS
- ✅ 2 NAT Gateways for HA
- ✅ Separate dev/prod environments
- ✅ EKS 1.34 with proper sizing

**Optional Additions:**
- [ ] RDS read replicas (if read-heavy)
- [ ] GuardDuty for threat detection
- [ ] AWS Config for compliance
- [ ] Secrets Manager auto-rotation
- [ ] Prometheus & Grafana monitoring
- [ ] CloudWatch alarms
- [ ] AWS Backup automation
- [ ] WAF for application protection

**Code Quality Tools:**
- [ ] pre-commit hooks
- [ ] tflint (best practices)
- [ ] tfsec (security scanning)
- [ ] terraform fmt (CI/CD)

See `docs/terraform-quality-tools.md` for setup instructions.

## 🤝 Contributing

Personal learning project, but feedback welcome! Open issues or reach out.

## 📄 License

MIT License

---

**Built with:** Terraform, AWS, Packer, Ansible, and lots of iteration 🚀

**Note:** Built from the ground up, not copied from templates. Every decision was conscious, every issue debugged, every improvement earned through learning.
