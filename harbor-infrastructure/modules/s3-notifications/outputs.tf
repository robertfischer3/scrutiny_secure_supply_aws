output "notification_id" {
  description = "ID of the bucket notification configuration"
  value       = aws_s3_bucket_notification.bucket_notification.id
}

output "updated_policy_id" {
  description = "ID of the updated SNS topic policy"
  value       = var.update_sns_policy ? aws_sns_topic_policy.update_topic_policy[0].id : null
}