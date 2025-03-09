variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "bucket_acl" {
  description = "The canned ACL to apply to the bucket"
  type        = string
  default     = "private"
}

variable "block_public_access" {
  description = "Whether to enable S3 block public access"
  type        = bool
  default     = true
}

variable "versioning_enabled" {
  description = "Whether to enable versioning for the bucket"
  type        = bool
  default     = true
}

variable "versioning_mfa_delete" {
  description = "Whether to enable MFA delete for versioning"
  type        = bool
  default     = false
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm (AES256 or aws:kms)"
  type        = string
  default     = "AES256"
}

variable "kms_master_key_id" {
  description = "KMS master key ID to use for SSE-KMS encryption"
  type        = string
  default     = null
}

variable "kms_master_key_arn" {
  description = "KMS master key ARN for replication permissions"
  type        = string
  default     = ""
}

variable "bucket_key_enabled" {
  description = "Whether to use S3 Bucket Keys for SSE-KMS"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Whether to allow the bucket to be destroyed even when not empty"
  type        = bool
  default     = false
}

variable "attach_policy" {
  description = "Whether to attach a custom policy to the bucket"
  type        = bool
  default     = false
}

variable "bucket_policy" {
  description = "Custom policy to attach to the bucket"
  type        = string
  default     = ""
}

variable "require_tls" {
  description = "Whether to require TLS for all bucket operations"
  type        = bool
  default     = true
}

# Lifecycle configuration
variable "lifecycle_rule_enabled" {
  description = "Whether to enable lifecycle rules"
  type        = bool
  default     = true
}

variable "lifecycle_expiration" {
  description = "Lifecycle rule expiration configuration"
  type        = any
  default     = null
}

variable "lifecycle_noncurrent_version_expiration" {
  description = "Lifecycle rule noncurrent version expiration configuration"
  type        = any
  default     = null
}

variable "lifecycle_transitions" {
  description = "Lifecycle rule transitions configuration"
  type        = list(any)
  default     = []
}

variable "lifecycle_noncurrent_version_transitions" {
  description = "Lifecycle rule noncurrent version transitions configuration"
  type        = list(any)
  default     = []
}

# Access logging
variable "enable_access_logging" {
  description = "Whether to enable access logging for the bucket"
  type        = bool
  default     = true
}

variable "access_log_bucket_name" {
  description = "Name of the bucket for access logs"
  type        = string
  default     = ""
}

variable "access_log_prefix" {
  description = "Prefix for access logs"
  type        = string
  default     = "s3-access-logs/"
}

# Object Lock
variable "object_lock_enabled" {
  description = "Whether to enable Object Lock for the bucket"
  type        = bool
  default     = false
}

variable "object_lock_mode" {
  description = "Object Lock retention mode (GOVERNANCE or COMPLIANCE)"
  type        = string
  default     = "GOVERNANCE"
}

variable "object_lock_days" {
  description = "Number of days for Object Lock retention period"
  type        = number
  default     = null
}

variable "object_lock_years" {
  description = "Number of years for Object Lock retention period"
  type        = number
  default     = null
}

# Cross-region replication
variable "enable_replication" {
  description = "Whether to enable cross-region replication"
  type        = bool
  default     = false
}

variable "replication_destination_bucket_arn" {
  description = "ARN of the destination bucket for replication"
  type        = string
  default     = ""
}

variable "replication_storage_class" {
  description = "Storage class to use for replicated objects"
  type        = string
  default     = "STANDARD"
}

variable "replication_kms_key_id" {
  description = "KMS key ID to use for encryption in the destination bucket"
  type        = string
  default     = null
}

variable "replication_kms_key_arn" {
  description = "KMS key ARN to use for encryption in the destination bucket"
  type        = string
  default     = ""
}

variable "replication_destination_account_id" {
  description = "Account ID of the destination bucket owner"
  type        = string
  default     = null
}

variable "replication_acl_translation" {
  description = "Whether to enable access control translation in replication"
  type        = bool
  default     = false
}

variable "replication_prefix" {
  description = "Prefix filter for replication rules"
  type        = string
  default     = ""
}

variable "replication_tags" {
  description = "Tag filters for replication rules"
  type        = map(string)
  default     = {}
}

variable "replication_delete_markers" {
  description = "Whether to replicate delete markers"
  type        = bool
  default     = true
}

variable "replication_region" {
  description = "AWS region of the destination bucket"
  type        = string
  default     = "us-west-2"
}

# CORS configuration
variable "enable_cors" {
  description = "Whether to enable CORS for the bucket"
  type        = bool
  default     = false
}

variable "cors_rule" {
  description = "CORS configuration for the bucket"
  type        = list(any)
  default     = []
}

# Intelligent tiering
variable "intelligent_tiering_enabled" {
  description = "Whether to enable intelligent tiering"
  type        = bool
  default     = false
}

variable "intelligent_tiering_prefix" {
  description = "Prefix filter for intelligent tiering"
  type        = string
  default     = ""
}

variable "intelligent_tiering_tags" {
  description = "Tag filters for intelligent tiering"
  type        = map(string)
  default     = {}
}

variable "intelligent_tiering_archive_days" {
  description = "Days after which to move objects to Archive Access tier"
  type        = number
  default     = 90
}

variable "intelligent_tiering_deep_archive_days" {
  description = "Days after which to move objects to Deep Archive Access tier"
  type        = number
  default     = 180
}

# Notifications
variable "enable_security_notifications" {
  description = "Whether to enable notifications for security events"
  type        = bool
  default     = false
}

variable "notification_topic_arn" {
  description = "ARN of the SNS topic for S3 event notifications"
  type        = string
  default     = ""
}

variable "notification_lambda_function_arn" {
  description = "ARN of the Lambda function for S3 event notifications"
  type        = string
  default     = ""
}

variable "security_notification_prefix" {
  description = "Prefix filter for security notifications"
  type        = string
  default     = ""
}

# Inventory
variable "enable_inventory" {
  description = "Whether to enable inventory reports"
  type        = bool
  default     = false
}

variable "inventory_destination_bucket_arn" {
  description = "ARN of the bucket for inventory reports"
  type        = string
  default     = ""
}

variable "inventory_destination_prefix" {
  description = "Prefix for inventory reports"
  type        = string
  default     = "inventory/"
}

variable "inventory_destination_account_id" {
  description = "Account ID of the inventory destination bucket owner"
  type        = string
  default     = null
}

# Ownership controls
variable "object_ownership" {
  description = "Object ownership setting (BucketOwnerPreferred, ObjectWriter, BucketOwnerEnforced)"
  type        = string
  default     = "BucketOwnerEnforced"
}

# AWS Region
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}