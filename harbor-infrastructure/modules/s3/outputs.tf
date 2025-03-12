output "s3_bucket_id" {
  description = "The name of the bucket"
  value       = module.s3_bucket.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "The ARN of the bucket"
  value       = module.s3_bucket.s3_bucket_arn
}

output "s3_bucket_domain_name" {
  description = "The domain name of the bucket"
  value       = module.s3_bucket.s3_bucket_bucket_domain_name
}

output "s3_bucket_regional_domain_name" {
  description = "The regional domain name of the bucket"
  value       = module.s3_bucket.s3_bucket_bucket_regional_domain_name
}

output "s3_bucket_region" {
  description = "The AWS region the bucket resides in"
  value       = module.s3_bucket.s3_bucket_region
}

output "s3_bucket_hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID for the bucket's region"
  value       = module.s3_bucket.s3_bucket_hosted_zone_id
}

output "s3_bucket_versioning_enabled" {
  description = "Whether versioning is enabled"
  value       = var.versioning_enabled
}

output "s3_bucket_sse_algorithm" {
  description = "The server-side encryption algorithm used"
  value       = var.sse_algorithm
}

output "replication_role_arn" {
  description = "The ARN of the IAM role used for replication"
  value       = var.enable_replication ? aws_iam_role.replication[0].arn : ""
}

output "replication_policy_arn" {
  description = "The ARN of the IAM policy used for replication"
  value       = var.enable_replication ? aws_iam_policy.replication[0].arn : ""
}

output "replication_enabled" {
  description = "Whether cross-region replication is enabled"
  value       = var.enable_replication
}

output "object_lock_enabled" {
  description = "Whether Object Lock is enabled"
  value       = var.object_lock_enabled
}

output "access_logging_enabled" {
  description = "Whether access logging is enabled"
  value       = var.enable_access_logging
}

output "lifecycle_rules_enabled" {
  description = "Whether lifecycle rules are enabled"
  value       = var.lifecycle_rule_enabled
}

# output "notification_configuration" {
#  description = "The notification configuration for the bucket"
#  value       = var.enable_security_notifications ? aws_s3_bucket_notification.security_notifications[0].topic : null
#}

output "inventory_enabled" {
  description = "Whether inventory reporting is enabled"
  value       = var.enable_inventory
}

output "bucket_policy_attached" {
  description = "Whether a custom bucket policy is attached"
  value       = var.attach_policy
}

output "require_tls_policy_attached" {
  description = "Whether a TLS requirement policy is attached"
  value       = var.require_tls && !var.attach_policy
}