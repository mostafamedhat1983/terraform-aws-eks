# AWS EKS Infrastructure with Terraform

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![Packer](https://img.shields.io/badge/packer-%23E7EEF0.svg?style=for-the-badge&logo=packer&logoColor=%2302A8EF)
![Ansible](https://img.shields.io/badge/ansible-%231A1918.svg?style=for-the-badge&logo=ansible&logoColor=white)
![Jenkins](https://img.shields.io/badge/jenkins-%232C5263.svg?style=for-the-badge&logo=jenkins&logoColor=white)
![MySQL](https://img.shields.io/badge/mysql-%2300f.svg?style=for-the-badge&logo=mysql&logoColor=white)

Production-ready AWS infrastructure managing **85+ cloud resources** across **2 environments** for **CI/CD automation**. Built from scratch over **5 months** to demonstrate enterprise-grade DevOps practices, modern AWS services (2023-2024), security hardening, and infrastructure as code principles. Every line of infrastructure code written, debugged, and deployed hands-on.

## 📦 Repository Scope

This repository provides the **infrastructure foundation** for the AWS EKS platform. It provisions AWS resources (VPC, EKS, RDS, networking, security) and prepares the cluster for application deployments. Application code, CI/CD pipelines, and Kubernetes manifests live in separate repositories, following platform engineering best practices.

## 🎯 Project Overview
!![repo 1](https://github.com/user-attachments/assets/b47d4767-8c8b-4c18-8b29-eff145e531a3)



Every line of code was written with intention, reviewed, debugged, and improved through multiple iterations. The infrastructure evolved from basic requirements to a secure, scalable, production-ready setup.

## 🏗️ Architecture

Two complete environments:   
**Development** ( ~$192/month )  
**Production** ( ~$259/month )

### Development Environment
**Cost-optimized for learning:**
- **VPC:** 2 AZs, 8 subnets (2 public, 6 private)
- **Compute:** 1x Jenkins Controller EC2 (t3.medium)
- **Database:** RDS MySQL 8.0 (db.t3.micro, single-AZ, 20GB, encrypted)
- **Kubernetes:** EKS 1.34 with 3x t3.small nodes (20GB disk)
- **Networking:** Regional NAT Gateway (high availability across AZs)
- **Registry:** ECR for Docker images
- **Secrets:** AWS Secrets Manager with init container retrieval

### Production Environment
**High availability and performance:**
- **VPC:** Same architecture for consistency
- **Compute:** 1x Jenkins Controller EC2 (t3.medium)
- **Database:** RDS MySQL 8.0 (db.t3.small, Multi-AZ, 50GB, 7-day backups, encrypted)
- **Kubernetes:** EKS 1.34 with 3x t3.medium nodes (30GB disk)
- **Networking:** Regional NAT Gateway (high availability across AZs)
- **Registry:** Shared ECR (different tags per environment)
- **Secrets:** Separate Secrets Manager per environment with init container retrieval

## 🛠️ What Makes This Different

**Built from scratch, not copied** - Every decision researched, debugged, and implemented through hands-on learning.

**Modern AWS Features (2023-2024):**
- **Regional NAT Gateway (December 2024)** - Single NAT Gateway with built-in high availability across all AZs, replacing zonal NAT Gateways
- **S3 Native State Locking (2024)** - `use_lockfile = true` instead of legacy DynamoDB approach
- **EKS Access Entry API (2023)** - Modern user/role access management, replacing deprecated `aws-auth` ConfigMap
- **EKS Pod Identity (2023)** - Simpler authentication for pods and CSI drivers, eliminating OIDC/IRSA complexity
- **EBS CSI Driver** - Persistent storage for stateful applications using Pod Identity
- **Init Container Secrets Management** - Direct AWS Secrets Manager integration for improved debugging and reduced complexity
- **ECR with IAM Authentication** - No Docker Hub credentials or rate limits

**Security & Architecture:**
- Comprehensive encryption (EBS, RDS, EKS secrets, S3) with zero secret exposure
- Private EKS endpoint accessed via Jenkins EC2 using SSM Session Manager (no bastion, no SSH keys, no public IPs)
- Flexible IAM role module reused for EC2, EKS, and Pod Identity by changing `service` parameter
- Jenkins IAM restricted to specific cluster ARNs (not wildcard `*`)
- Packer-built immutable AMIs with Trivy vulnerability scanning (not user data scripts)

**Code Quality:**
- Modular design with reusable Terraform modules (network, EC2, RDS, IAM, EKS)
- Descriptive naming (replaced numeric keys with "jenkins-2a", "eks-2a", "rds-2a")
- Dynamic configuration (no hardcoded AZs or values)
- Full variable documentation

## 🛠️ Technologies & Skills

**Core Stack:** AWS (EKS, RDS, EC2, VPC, IAM, Secrets Manager, ECR, KMS) • Terraform • Kubernetes • Docker • Packer • Ansible • Jenkins • MySQL

**Key Capabilities:**
- **Infrastructure as Code:** Terraform modules, state management, S3 native locking, multi-environment deployments
- **Container Orchestration:** EKS cluster management, Pod Identity, EBS CSI Driver, Kubernetes RBAC, resource management
- **CI/CD Infrastructure:** Jenkins installation and setup, Packer AMI builds, Ansible configuration management, immutable infrastructure
- **Security:** Zero-trust architecture, encryption (KMS), IAM least privilege, Secrets Manager with Pod Identity, vulnerability scanning (Trivy), SSM Session Manager
- **Cloud Architecture:** Multi-AZ design, high availability, automated backups, network isolation, cost optimization

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
- **Trivy:** Vulnerability scanning (fails on CRITICAL)

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

- **Regional NAT Gateway:** Single NAT Gateway with built-in high availability across all AZs ($35/mo), replacing zonal NAT Gateways
- **EBS CSI Driver:** Persistent storage using Pod Identity for stateful applications
- **Secrets Management:** AWS Secrets Manager with Pod Identity. Init container implementation in application repository
- **Jenkins Architecture:** Controller on EC2 + ephemeral agents as EKS pods (cost-effective, scalable)
- **SSM Session Manager:** Secure access without bastion hosts, SSH keys, or public endpoints
- **RDS Secrets:** Manual creation outside Terraform ensures persistence across `terraform destroy`
- **Immutable AMIs:** Packer + Ansible for consistency, not AWS "latest" or user data scripts

[View detailed architecture decisions →](docs/architecture-decisions.md)  
[View complete security documentation →](docs/security.md)

## 🚀 Deployment

**Prerequisites:** 
- AWS CLI configured with appropriate credentials and access to us-east-2 region
- Terraform >= 1.0
- Packer >= 1.8 (for AMI builds)
- Ansible >= 2.9 (for provisioning)
- S3 bucket for Terraform state storage with versioning enabled
- ECR repository created (for Docker images)

**0. Create S3 Bucket for Terraform State:**
```bash
# Create S3 bucket for state storage (update bucket name to be unique)
aws s3 mb s3://your-terraform-state-bucket --region us-east-2

# Enable versioning for state recovery
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled \
  --region us-east-2

# Update backend.tf files with your bucket name
# terraform/dev/backend.tf and terraform/prod/backend.tf
```

**1. Create ECR Repository:**
```bash
# Create ECR repository for Docker images
aws ecr create-repository \
  --repository-name platform-app \
  --region us-east-2
```

**2. Create RDS Secrets:**

Initial secrets need only `username`, `password`, and `dbname`. The RDS module automatically updates with `host` and `port` after database creation.

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

*Note: Application init containers fetch complete credentials (including host/port) automatically.*

**3. Build Jenkins AMI:**
```bash
cd packer
packer init jenkins.pkr.hcl
packer build jenkins.pkr.hcl  # Includes Ansible provisioning and Trivy scanning
# Note: AMI ID will be saved to manifest.json
```

**4. Deploy Infrastructure:**

```bash
cd terraform/dev  # or terraform/prod
terraform init
terraform plan    # Review changes before applying
terraform apply
```

**5. Access Jenkins and Configure kubectl:**

```bash
# Connect to Jenkins EC2 instance via SSM (no SSH keys needed)
aws ssm start-session --target <jenkins-instance-id> --region us-east-2

# Once connected, configure kubectl for EKS access
aws eks update-kubeconfig --name platform-dev --region us-east-2

# Verify cluster access
kubectl get nodes
```

**Timing:**

- S3 bucket creation: ~1 min
- ECR repository creation: ~1 min
- Secrets creation: ~1 min
- Packer AMI build: ~10-15 min
- First Terraform apply: ~20-25 min
- Subsequent updates: ~2-5 min

## 🔧 Post-Deployment: Jenkins-Kubernetes Integration

**Configure Jenkins for dynamic EKS agent provisioning (5 min):**

```bash
# Connect and create service account
aws ssm start-session --target <jenkins-instance-id> --region us-east-2
aws eks update-kubeconfig --name platform-dev --region us-east-2
kubectl create serviceaccount jenkins-sa -n default
kubectl create clusterrolebinding jenkins-admin --clusterrole=cluster-admin --serviceaccount=default:jenkins-sa
kubectl create token jenkins-sa --duration=8760h -n default  # Copy output
```

**Add to Jenkins:** Manage Jenkins → Credentials → Add (Kind: Secret text, ID: `jenkins-k8s-token`)  
**Configure Cloud:** Manage Jenkins → Configure Clouds → Add Kubernetes  
- URL: `https://<eks-endpoint>` | Namespace: default | Credentials: jenkins-k8s-token  
- ☑️ Disable https certificate check | ☑️ WebSocket (required)

[Detailed guide →](docs/jenkins-kubernetes-integration.md)

## 📊 Cost Analysis

**Development:** ~$192/month (cost-optimized for learning)  
**Production:** ~$259/month (high availability and performance)

**Regional NAT Gateway Savings:** Prod saves ~$33/month compared to 2 zonal NAT Gateways while maintaining high availability across all AZs.

Strategic cost vs security tradeoffs learned through hands-on experimentation. Pricing based on us-east-2 region (2025).

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
8. Testing architectural decisions reveals practical limitations not visible in documentation

## 🔄 Architecture Evolution

Real infrastructure evolves through testing and iteration:

**Secrets Management Journey:**
Initially implemented AWS Secrets Store CSI Driver following best practices documentation. After hands-on testing, identified debugging challenges (logs in kube-system namespace), architectural complexity (CSI driver → SecretProviderClass → volume mount), and limited error visibility. 

Pivoted to **init container approach** after evaluation:
- ✅ Simpler debugging: logs in application pod (`kubectl logs <pod> -c fetch-secrets`)
- ✅ Better error visibility: direct AWS API error messages
- ✅ Reduced complexity: eliminated CSI addon and ~60 lines of infrastructure code
- ✅ Direct control: full visibility into secret retrieval logic
- ⚠️ Trade-off: manual pod restart for secret rotation (acceptable for infrequent DB credential changes)

**Lesson:** "Best practices" are context-dependent. Test implementations against your requirements, not just documentation recommendations. Being willing to refactor after evaluation demonstrates engineering maturity.

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
