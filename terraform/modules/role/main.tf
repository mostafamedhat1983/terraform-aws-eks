# ========================================
# IAM Role
# ========================================
# Creates a flexible IAM role that can be assumed by different AWS services
# Supports: EC2, EKS cluster, and EKS pods (Pod Identity)

resource "aws_iam_role" "this" {
  name = var.name

  # Trust policy: Allows specified AWS service to assume this role
  # For pods.eks.amazonaws.com: Adds sts:TagSession action (required for Pod Identity)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = var.service == "pods.eks.amazonaws.com" ? [
          "sts:AssumeRole", "sts:TagSession"
        ] : ["sts:AssumeRole"]
        Effect = "Allow"
        Principal = {
          Service = var.service
        }
      },
    ]
  })
}

# ========================================
# Policy Attachments
# ========================================
# Attaches managed policies to the IAM role
# Supports multiple policies via count loop

resource "aws_iam_role_policy_attachment" "this" {
  count      = length(var.policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = var.policy_arns[count.index]
}

# ========================================
# Instance Profile (EC2 Only)
# ========================================
# Creates instance profile only when service is EC2
# Not needed for EKS cluster or Pod Identity roles

resource "aws_iam_instance_profile" "this" {
  count = var.service == "ec2.amazonaws.com" ? 1 : 0
  name  = var.name
  role  = aws_iam_role.this.name
}
