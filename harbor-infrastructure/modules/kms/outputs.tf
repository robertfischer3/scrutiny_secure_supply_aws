output "key_id" {
  description = "The ID of the KMS key"
  value       = local.key_id
}

output "key_arn" {
  description = "The ARN of the KMS key"
  value       = local.key_arn
}

output "alias_name" {
  description = "The alias of the KMS key"
  value       = var.alias_name
}

output "alias_arn" {
  description = "The ARN of the KMS key alias"
  value       = local.create_key || (var.is_testing_mode && var.existing_key_id != "") ? aws_kms_alias.this[0].arn : ""
}

output "key_usage" {
  description = "The usage of the KMS key (ENCRYPT_DECRYPT or SIGN_VERIFY)"
  value       = var.key_usage
}

output "key_spec" {
  description = "The type of key material in the KMS key"
  value       = var.customer_master_key_spec
}

output "s3_grant_id" {
  description = "The unique ID of the S3 grant"
  value       = var.enable_s3_grants ? aws_kms_grant.s3[0].id : null
}

output "rds_grant_id" {
  description = "The unique ID of the RDS grant"
  value       = var.enable_rds_grants ? aws_kms_grant.rds[0].id : null
}

output "ebs_grant_id" {
  description = "The unique ID of the EBS grant"
  value       = var.enable_ebs_grants ? aws_kms_grant.ebs[0].id : null
}

output "efs_grant_id" {
  description = "The unique ID of the EFS grant"
  value       = var.enable_efs_grants ? aws_kms_grant.efs[0].id : null
}

output "key_policy" {
  description = "The policy document applied to the KMS key"
  value       = var.enable_default_policy ? data.aws_iam_policy_document.default[0].json : var.key_policy
}

output "key_rotation_enabled" {
  description = "Whether key rotation is enabled"
  value       = var.enable_key_rotation
}

output "deletion_window_in_days" {
  description = "Duration in days after which the key is deleted"
  value       = var.deletion_window_in_days
}