# harbor-infrastructure/modules/iam/outputs.tf

output "harbor_kms_admin_role_arn" {
  description = "The ARN of the Harbor KMS Admin role"
  value       = aws_iam_role.harbor_kms_admin.arn
}

output "harbor_kms_admin_role_name" {
  description = "The name of the Harbor KMS Admin role"
  value       = aws_iam_role.harbor_kms_admin.name
}

output "harbor_kms_user_role_arn" {
  description = "The ARN of the Harbor KMS User role"
  value       = aws_iam_role.harbor_kms_user.arn
}

output "harbor_kms_user_role_name" {
  description = "The name of the Harbor KMS User role"
  value       = aws_iam_role.harbor_kms_user.name
}

output "harbor_admin_role_arn" {
  description = "The ARN of the Harbor Admin role"
  value       = aws_iam_role.harbor_admin.arn
}

output "harbor_admin_role_name" {
  description = "The name of the Harbor Admin role"
  value       = aws_iam_role.harbor_admin.name
}

output "harbor_operator_role_arn" {
  description = "The ARN of the Harbor Operator role"
  value       = aws_iam_role.harbor_operator.arn
}

output "harbor_operator_role_name" {
  description = "The name of the Harbor Operator role"
  value       = aws_iam_role.harbor_operator.name
}

output "harbor_kms_admin_instance_profile_arn" {
  description = "The ARN of the Harbor KMS Admin instance profile"
  value       = var.create_instance_profiles ? aws_iam_instance_profile.harbor_kms_admin[0].arn : null
}

output "harbor_kms_user_instance_profile_arn" {
  description = "The ARN of the Harbor KMS User instance profile"
  value       = var.create_instance_profiles ? aws_iam_instance_profile.harbor_kms_user[0].arn : null
}

output "harbor_admin_instance_profile_arn" {
  description = "The ARN of the Harbor Admin instance profile"
  value       = var.create_instance_profiles ? aws_iam_instance_profile.harbor_admin[0].arn : null
}

output "harbor_operator_instance_profile_arn" {
  description = "The ARN of the Harbor Operator instance profile"
  value       = var.create_instance_profiles ? aws_iam_instance_profile.harbor_operator[0].arn : null
}