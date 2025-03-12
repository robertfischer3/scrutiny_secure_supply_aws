output "topic_arn" {
  description = "The ARN of the SNS topic"
  value       = aws_sns_topic.this.arn
}

output "topic_id" {
  description = "The ID of the SNS topic"
  value       = aws_sns_topic.this.id
}

output "topic_name" {
  description = "The name of the SNS topic"
  value       = aws_sns_topic.this.name
}

output "topic_owner" {
  description = "The AWS account that owns the SNS topic"
  value       = aws_sns_topic.this.owner
}

output "subscription_arns" {
  description = "ARNs of the SNS topic subscriptions"
  value       = concat(
    aws_sns_topic_subscription.email[*].arn,
    aws_sns_topic_subscription.lambda[*].arn
  )
}