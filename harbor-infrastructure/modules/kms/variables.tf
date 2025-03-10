variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "is_testing_mode" {
  description = "Whether we're running in testing mode (affects key creation behavior)"
  type        = bool
  default     = false
}


variable "existing_key_id" {
  description = "ID of an existing KMS key to use during testing instead of creating a new one"
  type        = string
  default     = ""
}

variable "skip_creation" {
  description = "Skip creation of KMS resources entirely (useful when key is pending deletion)"
  type        = bool
  default     = false
}

variable "alias_name" {
  description = "Alias name for the KMS key"
  type        = string
  default     = "alias/harbor-key"
}

variable "description" {
  description = "Description for the KMS key"
  type        = string
  default     = "KMS key for Harbor encryption"
}

variable "deletion_window_in_days" {
  description = "Duration in days after which the key is deleted after destruction of the resource"
  type        = number
  default     = 30
  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "Deletion window must be between 7 and 30 days."
  }
}

variable "enable_key_rotation" {
  description = "Specifies whether key rotation is enabled"
  type        = bool
  default     = true
}

variable "key_usage" {
  description = "Specifies the intended use of the key"
  type        = string
  default     = "ENCRYPT_DECRYPT"
  validation {
    condition     = var.key_usage == "ENCRYPT_DECRYPT" || var.key_usage == "SIGN_VERIFY"
    error_message = "Key usage must be either ENCRYPT_DECRYPT or SIGN_VERIFY."
  }
}

variable customer_master_key_spec {
  description = "Specifies the type of KMS key to create"
  type        = string
  default     = "SYMMETRIC_DEFAULT"
}

variable "enable_default_policy" {
  description = "Specifies whether to use a default policy or a custom one"
  type        = bool
  default     = true
}

variable "key_policy" {
  description = "A valid policy JSON document for the KMS key"
  type        = string
  default     = null
}

variable "key_administrators" {
  description = "List of IAM ARNs for key administrators"
  type        = list(string)
  default     = []
}

variable "key_users" {
  description = "List of IAM ARNs for key users"
  type        = list(string)
  default     = []
}

variable "attach_to_eks_role" {
  description = "Whether to allow EKS cluster role to use the key"
  type        = bool
  default     = false
}

variable "eks_cluster_role_name" {
  description = "Name of the EKS cluster IAM role"
  type        = string
  default     = ""
}

variable "enable_secretsmanager_grants" {
  description = "Whether to allow Secrets Manager to use the key"
  type        = bool
  default     = true
}

variable "enable_s3_grants" {
  description = "Whether to create KMS grants for S3"
  type        = bool
  default     = true
}

variable "enable_rds_grants" {
  description = "Whether to create KMS grants for RDS"
  type        = bool
  default     = true
}

variable "enable_ebs_grants" {
  description = "Whether to create KMS grants for EBS"
  type        = bool
  default     = true
}

variable "enable_efs_grants" {
  description = "Whether to create KMS grants for EFS"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
