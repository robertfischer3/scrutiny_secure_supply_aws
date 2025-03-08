variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "name" {
  description = "Name of the EFS file system"
  type        = string
}

variable "encrypted" {
  description = "Whether to enable encryption for the EFS file system"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "ARN of the KMS key used to encrypt the EFS file system"
  type        = string
  default     = null
}

variable "performance_mode" {
  description = "Performance mode of the EFS file system (generalPurpose or maxIO)"
  type        = string
  default     = "generalPurpose"
  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "Performance mode must be either generalPurpose or maxIO."
  }
}

variable "throughput_mode" {
  description = "Throughput mode of the EFS file system (bursting, provisioned, or elastic)"
  type        = string
  default     = "bursting"
  validation {
    condition     = contains(["bursting", "provisioned", "elastic"], var.throughput_mode)
    error_message = "Throughput mode must be one of: bursting, provisioned, or elastic."
  }
}

variable "provisioned_throughput_in_mibps" {
  description = "Provisioned throughput in MiB/s (required if throughput_mode is provisioned)"
  type        = number
  default     = null
}

variable "lifecycle_policy" {
  description = "List of lifecycle policies for the EFS file system"
  type        = list(map(string))
  default     = []
}

variable "enable_protection" {
  description = "Whether to enable protection against accidental deletion for the EFS file system"
  type        = bool
  default     = true
}

variable "backup_policy" {
  description = "Backup policy for the EFS file system"
  type        = map(string)
  default     = {
    status = "ENABLED"
  }
}

variable "vpc_id" {
  description = "ID of the VPC where the EFS file system will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where mount targets will be created"
  type        = list(string)
}

variable "security_group_rules" {
  description = "Map of security group rules to add to the security group created"
  type        = map(any)
  default     = {}
}

variable "create_access_point" {
  description = "Whether to create an access point for the EFS file system"
  type        = bool
  default     = false
}

variable "access_point_posix_user" {
  description = "POSIX user configuration for the access point"
  type        = object({
    gid = number
    uid = number
  })
  default     = {
    gid = 0
    uid = 0
  }
}

variable "access_point_root_directory" {
  description = "Root directory configuration for the access point"
  type        = object({
    path = string
    creation_info = object({
      owner_gid   = number
      owner_uid   = number
      permissions = string
    })
  })
  default     = {
    path = "/"
    creation_info = {
      owner_gid   = 0
      owner_uid   = 0
      permissions = "755"
    }
  }
}

variable "enable_replication" {
  description = "Whether to enable replication for the EFS file system"
  type        = bool
  default     = false
}

variable "replication_destination_region" {
  description = "AWS region where the EFS file system will be replicated"
  type        = string
  default     = "us-west-2"
}

variable "replication_kms_key_id" {
  description = "ARN of the KMS key used to encrypt the replicated EFS file system"
  type        = string
  default     = null
}

variable "create_backup_plan" {
  description = "Whether to create a backup plan for the EFS file system"
  type        = bool
  default     = true
}

variable "backup_schedule" {
  description = "Backup schedule for the EFS file system in cron format"
  type        = string
  default     = "cron(0 1 * * ? *)" # Daily at 1:00 AM UTC
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "create_cloudwatch_alarms" {
  description = "Whether to create CloudWatch alarms for the EFS file system"
  type        = bool
  default     = true
}

variable "burst_credit_balance_threshold" {
  description = "Threshold for the burst credit balance alarm (in bytes)"
  type        = number
  default     = 1000000000 # 1GB in bytes
}

variable "percent_io_limit_threshold" {
  description = "Threshold for the percent I/O limit alarm"
  type        = number
  default     = 80
}

variable "alarm_actions" {
  description = "List of ARNs of actions to take when the alarm transitions to the ALARM state"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Map of tags to add to all resources"
  type        = map(string)
  default     = {}
}