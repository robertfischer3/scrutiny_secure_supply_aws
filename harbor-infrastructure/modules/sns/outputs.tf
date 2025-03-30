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

output "policy_id" {
  description = "The ID of the SNS topic policy"
  value       = aws_sns_topic_policy.default.id
}