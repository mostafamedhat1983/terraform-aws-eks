# Packer - Jenkins AMI Builder

Builds custom Jenkins AMI with pre-installed tools using Amazon Linux 2023.

## What It Does
- Creates AMI from Amazon Linux 2023 base image
- Provisions with Ansible (installs Docker, Jenkins, kubectl, Helm, etc.)
- Runs Trivy security scan (fails on CRITICAL vulnerabilities)
- Outputs AMI ID to `manifest.json`

## Build Commands
```bash
cd packer
packer init jenkins.pkr.hcl
packer build jenkins.pkr.hcl
```

## Output
- **AMI:** `jenkins-YYYY-MM-DD-hhmm` in us-east-2
- **Manifest:** `manifest.json` (contains AMI ID for Terraform reference)
- **Security Report:** `trivy-report-YYYY-MM-DD-hhmm.json`

## Configuration
- **Base Image:** Amazon Linux 2023 (latest)
- **Build Instance:** t3.medium
- **Region:** us-east-2
- **Provisioner:** Ansible playbook at `ansible/jenkins-playbook.yml`

## Security
- GPG verification for all third-party repos
- Trivy vulnerability scanning (exit-code 1 on CRITICAL)
- SSH password authentication disabled
- All installations verified before AMI creation

## Notes
- Build takes ~10-15 minutes
- Terraform automatically uses latest AMI via data source lookup
- Keep `manifest.json` for reference (gitignored)
