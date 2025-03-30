variable "bucket_id" {
  description = "ID of the S3 bucket"
  type        = string
}

variable "topic_arn" {
  description = "ARN of the SNS topic"
  type        = string
}

variable "topic_name" {
  description = "Name of the SNS topic"
  type        = string
}

variable "events" {
  description = "List of events to trigger notifications"
  type        = list(string)
  default     = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
}

variable "filter_prefix" {
  description = "Object key prefix for filtering notifications"
  type        = string
  default     = ""
}

variable "filter_suffix" {
  description = "Object key suffix for filtering notifications"
  type        = string
  default     = ""
}

variable "update_sns_policy" {
  description = "Whether to update the SNS topic policy"
  type        = bool
  default     = true
}