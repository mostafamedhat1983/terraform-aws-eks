# AWS EKS Infrastructure with Terraform

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Packer](https://img.shields.io/badge/packer-%23E7EEF0.svg?style=for-the-badge&logo=packer&logoColor=%2302A8EF)
![Ansible](https://img.shields.io/badge/ansible-%231A1918.svg?style=for-the-badge&logo=ansible&logoColor=white)
![Jenkins](https://img.shields.io/badge/jenkins-%232C5263.svg?style=for-the-badge&logo=jenkins&logoColor=white)
![MySQL](https://img.shields.io/badge/mysql-%2300f.svg?style=for-the-badge&logo=mysql&logoColor=white)

Production-ready AWS infrastructure managing **50+ cloud resources** across **2 environments** with **full CI/CD automation**. Built from scratch over **3 months** to demonstrate enterprise-grade DevOps practices, modern AWS services (2023-2024), security hardening, and infrastructure as code principles. Every line of infrastructure code written, debugged, and deployed hands-on.

## 🎯 Skills Demonstrated

**Cloud & Infrastructure:**
- AWS Cloud Architecture (VPC, Subnets, Route Tables, Security Groups, NAT Gateway, Internet Gateway)
- Amazon EKS (Elastic Kubernetes Service) - cluster management, node groups, control plane configuration
- Amazon RDS (Relational Database Service) - MySQL, Multi-AZ, automated backups, encryption
- Amazon EC2 (Elastic Compute Cloud) - instance management, EBS volumes, SSM Session Manager
- AWS IAM (Identity and Access Management) - roles, policies, least privilege access, service principals
- AWS Secrets Manager - secret rotation, KMS encryption, secrets lifecycle management
- Amazon ECR (Elastic Container Registry) - Docker image management
- AWS KMS (Key Management Service) - encryption key management, key rotation

**Infrastructure as Code (IaC):**
- Terraform - modules, state management, workspaces, remote backends, S3 native locking
- HashiCorp Configuration Language (HCL)
- Infrastructure modularization and reusability
- State file management and locking strategies

**Container Orchestration & Kubernetes:**
- Kubernetes architecture and resource management
- EKS Pod Identity (modern IRSA alternative)
- Kubernetes CSI Drivers (EBS CSI, AWS Secrets Store CSI)
- Container networking and storage
- Docker containerization
- Helm package management

**Configuration Management & Automation:**
- Packer - AMI automation and image building
- Ansible - configuration management, idempotent playbooks, native modules
- Jenkins - CI/CD pipeline orchestration, Kubernetes plugin
- Infrastructure automation and immutable infrastructure patterns

**Security & Compliance:**
- Zero-trust security architecture
- Encryption at rest and in transit (KMS, TLS)
- Network isolation and private subnets
- Security group and NACL configuration
- Vulnerability scanning (Trivy)
- Secrets management and rotation
- IAM least privilege access patterns
- AWS security best practices and compliance

**DevOps Practices:**
- CI/CD pipeline design and implementation
- Infrastructure automation and orchestration
- Multi-environment deployment strategies (dev/prod)
- Cost optimization and resource right-sizing
- Monitoring and logging (CloudWatch)
- Disaster recovery and high availability design

**Technical Skills:**
- Linux system administration (Amazon Linux 2023)
- Bash scripting and automation
- Git version control
- Documentation and technical writing
- Problem-solving and debugging
- Architecture design and decision-making

## 📦 Repository Scope

This repository provides the **infrastructure foundation** for the AWS EKS platform. It provisions AWS resources (VPC, EKS, RDS, networking, security) and prepares the cluster for application deployments. Application code, CI/CD pipelines, and Kubernetes manifests live in separate repositories, following platform engineering best practices.

## 🎯 Project Overview
![Diagram 2](https://github.com/user-attachments/assets/5c3da0df-e013-40f0-a8db-497557604b88)



Every line of code was written with intention, reviewed, debugged, and improved through multiple iterations. The infrastructure evolved from basic requirements to a secure, scalable, production-ready setup.

## 🏗️ Architecture

Two complete environments:  
**Development**  (~$180/month)  
**Production**  ( ~$340/month).

### Development Environment
**Cost-optimized for learning:**
- **VPC:** 2 AZs, 8 subnets (2 public, 6 private)
- **Compute:** 1x Jenkins Controller EC2 (t3.medium)
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

**Built from scratch, not copied** - Every decision researched, debugged, and implemented through hands-on learning.

**Modern AWS Features (2023-2024):**
- **S3 Native State Locking (2024)** - `use_lockfile = true` instead of legacy DynamoDB approach
- **EKS Access Entry API (2023)** - Modern user/role access management, replacing deprecated `aws-auth` ConfigMap
- **EKS Pod Identity (2023)** - Simpler authentication for CSI drivers, eliminating OIDC/IRSA complexity
- **Dual CSI Driver Setup** - EBS CSI for persistent storage + AWS Secrets Store CSI for mounting secrets from Secrets Manager directly into pods
- **ECR with IAM Authentication** - No Docker Hub credentials or rate limits

**Security & Architecture:**
- Comprehensive encryption (EBS, RDS, EKS secrets, S3) with zero secret exposure
- Private EKS endpoint accessed via SSM Session Manager (no bastion, no SSH keys)
- Flexible IAM role module reused for EC2, EKS, and Pod Identity by changing `service` parameter
- Jenkins IAM restricted to specific cluster ARNs (not wildcard `*`)
- Packer-built immutable AMIs with Trivy vulnerability scanning (not user data scripts)

**Code Quality:**
- Modular design with reusable Terraform modules (network, EC2, RDS, IAM, EKS)
- Descriptive naming (replaced numeric keys with "jenkins-2a", "eks-2a", "rds-2a")
- Dynamic configuration (no hardcoded AZs or values)
- Full variable documentation

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

AMI builds include automated vulnerability scanning with Trivy v0.67.2. Scans entire root filesystem and fails builds on CRITICAL severity. Current status: 0 CRITICAL vulnerabilities.

## 💡 Key Technical Decisions

Every architecture decision made through research and understanding of tradeoffs:

- **NAT Gateway Strategy:** 1 NAT for dev (cost-optimized $35/mo), 2 NATs for prod (high availability $70/mo)
- **EKS CSI Drivers:** EBS CSI for persistent volumes + Secrets Store CSI for mounting secrets, both using Pod Identity
- **Jenkins Architecture:** Controller on EC2 + ephemeral agents as EKS pods (cost-effective, scalable)
- **SSM Session Manager:** Secure access without bastion hosts, SSH keys, or public endpoints
- **Secrets Management:** Manual creation outside Terraform ensures persistence across `terraform destroy`
- **Immutable AMIs:** Packer + Ansible for consistency, not AWS "latest" or user data scripts

[View detailed architecture decisions →](docs/architecture-decisions.md)  
[View complete security documentation →](docs/security.md)

## 🚀 Deployment

**Prerequisites:** AWS CLI, Terraform >= 1.0, S3 bucket for state, Secrets Manager secrets

**1. Create RDS Secrets:**
```bash
# Dev
aws secretsmanager create-secret \
  --name platform-db-dev-credentials \
  --secret-string '{"username":"admin","password":"YourDevPassword","dbname":"platformdb"}' \
  --region us-east-2

# Prod
aws secretsmanager create-secret \
  --name platform-db-prod-credentials \
  --secret-string '{"username":"admin","password":"YourStrongProdPassword","dbname":"platformdb"}' \
  --region us-east-2
```

**2. Build Jenkins AMI:**
```bash
cd packer
packer init jenkins.pkr.hcl
packer build jenkins.pkr.hcl  # Includes Ansible provisioning and Trivy scanning
```

**3. Deploy Infrastructure:**
```bash
cd terraform/dev  # or terraform/prod
terraform init
terraform plan    # Review changes before applying
terraform apply
```

**4. Configure kubectl:**
```bash
aws ssm start-session --target <jenkins-instance-id>
aws eks update-kubeconfig --name platform-dev --region us-east-2
```

**Timing:** Packer build ~10-15 min, first Terraform apply ~20-25 min, updates 2-5 min

## 📊 Cost Analysis

**Development:** ~$165/month (cost-optimized for learning)  
**Production:** ~$310/month (high availability and performance)

Strategic cost vs security tradeoffs learned through hands-on experimentation.

[View detailed cost breakdown →](docs/cost-breakdown.md)

## 🤖 AI-Assisted Development

Built with **Amazon Q** and **Gemini Code Assist** as productivity tools for code review, documentation, and debugging. Architecture design, module creation, and all technical decisions were human-made. Every line was reviewed, understood, and intentionally committed.

## 🎓 Key Learnings

1. Building modular, reusable Terraform modules saves time and reduces errors
2. Packer-built AMI provides consistency and stability (not AWS "latest" AMI)
3. Strategic cost vs security tradeoffs (dev can make reasonable compromises)
4. Defense in depth: encryption + IAM + network isolation + logging
5. Deep dive into VPC, EKS, RDS, Secrets Manager, SSM, Pod Identity
6. Documentation matters for future-you
7. Iterative improvements from code review catch integration issues

## 🔮 Future Enhancements

The infrastructure is production-ready with Multi-AZ RDS, HA NAT Gateways, and proper sizing. Optional enhancements like GuardDuty, Prometheus/Grafana, and code quality tools can be added based on requirements.

[View enhancement roadmap →](docs/future-enhancements.md)

## 🤝 Contributing

Personal learning project, but feedback welcome! Open issues or reach out.

## 📄 License

MIT License

---

**Built with:** Terraform, AWS, Packer, Ansible, and lots of iteration 🚀

**Note:** Built from the ground up, not copied from templates. Every decision was conscious, every issue debugged, every improvement earned through learning.
