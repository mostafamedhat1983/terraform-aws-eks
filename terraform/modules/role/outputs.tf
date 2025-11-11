output "role_id" {
  description = "The ID of the IAM role"
  value       = aws_iam_role.this.id
}

output "instance_profile_name" {
  description = "The name of the instance profile"
  value       = var.service == "ec2.amazonaws.com" ? aws_iam_instance_profile.this[0].name : null
}

output "role_arn" {
  description = "The ARN of the IAM role"
  value       = aws_iam_role.this.arn
}
