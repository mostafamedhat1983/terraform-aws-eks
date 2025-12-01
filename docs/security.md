# Security Features

Comprehensive security implementation across all layers of the infrastructure.

## Security Features Checklist

- ✅ All data encrypted at rest (EBS, RDS, EKS secrets, S3)
- ✅ IAM roles with least privilege (no hardcoded credentials)
- ✅ Private subnets for all workloads
- ✅ Security groups with specific rules (no 0.0.0.0/0 ingress)
- ✅ EKS control plane logging to CloudWatch
- ✅ SSM Session Manager (no bastion host or SSH keys)
- ✅ Secrets Manager for database credentials with Pod Identity
- ✅ KMS key rotation enabled for EKS secrets encryption
- ✅ S3 state versioning enabled

## Zero Secret Exposure

- RDS credentials in Secrets Manager (encrypted with KMS)
- Secrets created manually outside Terraform
- Terraform reads via `data` source (no plaintext)
- Pod Identity grants least-privilege access to Secrets Manager
- Application uses init containers for secret retrieval (implementation in platform-ai-chatbot repository)
- Secrets encrypted in transit and at rest in EKS (KMS encryption with automatic rotation)
- Passwords never in Git, code, state files, logs, or container images
- S3 versioning + native locking + encryption for state files

## Network Security

- All workloads in private subnets
- RDS not publicly accessible
- EKS API endpoint private-only
- NAT Gateway for controlled outbound access

## Security Scanning

AMI builds include automated vulnerability scanning with Trivy v0.67.2. Scans entire root filesystem and fails builds on CRITICAL severity. Current status: 0 CRITICAL vulnerabilities.
