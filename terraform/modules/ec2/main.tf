# ========================================
# EC2 Instance
# ========================================
# Creates EC2 instance with encrypted EBS volume
# Used for: Jenkins controller

resource "aws_instance" "this" {
  ami                    = var.ami
  instance_type          = var.instance_type
  availability_zone      = var.availability_zone
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  iam_instance_profile   = var.iam_instance_profile

  # Root volume encrypted for security compliance
  root_block_device {
    encrypted = true
  }

  tags = var.tags
}