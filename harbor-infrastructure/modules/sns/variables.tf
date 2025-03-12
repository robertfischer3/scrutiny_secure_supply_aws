variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "topic_name" {
  description = "Name for the SNS topic"
  type        = string
}

variable "display_name" {
  description = "Display name for the SNS topic"
  type        = string
  default     = ""
}

variable "kms_key_id" {
  description = "KMS key ID for SNS topic encryption"
  type        = string
  default     = ""
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs that are allowed to publish to this topic"
  type        = list(string)
  default     = []
}

variable "email_subscriptions" {
  description = "List of email addresses to subscribe to the topic"
  type        = list(string)
  default     = []
}

variable "lambda_function_arn" {
  description = "ARN of Lambda function to subscribe to the topic"
  type        = string
  default     = ""
}

variable "lambda_function_name" {
  description = "Name of Lambda function to subscribe to the topic (if different from ARN)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Map of tags to add to all resources"
  type        = map(string)
  default     = {}
}