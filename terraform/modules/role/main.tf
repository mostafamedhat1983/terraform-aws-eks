resource "aws_iam_role" "this" {
  name = var.name

  # Allows a service to assume this role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = var.service
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  count      = length(var.policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = var.policy_arns[count.index]
}

resource "aws_iam_instance_profile" "this" {
  count = var.service == "ec2.amazonaws.com" ? 1 : 0
  name = var.name
  role = aws_iam_role.this.name
}
