variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

# Basic Configuration
variable "identifier" {
  description = "The name of the RDS instance"
  type        = string
}

variable "engine" {
  description = "The database engine to use"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "The database engine version to use"
  type        = string
  default     = "15.3"
}

variable "family" {
  description = "The family of the DB parameter group"
  type        = string
  default     = null
}

variable "major_engine_version" {
  description = "Specifies the major version of the engine that this option group should be associated with"
  type        = string
  default     = null
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.t3.medium"
}

# Storage Configuration
variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "The upper limit to which Amazon RDS can automatically scale the storage"
  type        = number
  default     = 100
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted"
  type        = bool
  default     = true
}

variable "storage_type" {
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), 'gp3' (general purpose SSD), or 'io1' (provisioned IOPS SSD)"
  type        = string
  default     = "gp3"
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key"
  type        = string
  default     = null
}

# Database Authentication
variable "db_name" {
  description = "The name of the database to create when the DB instance is created"
  type        = string
  default     = "registry"
}

variable "username" {
  description = "Username for the master DB user"
  type        = string
  default     = "harboradmin"
}

variable "password" {
  description = "Password for the master DB user"
  type        = string
  sensitive   = true
  default     = null
}

variable "port" {
  description = "The port on which the DB accepts connections"
  type        = number
  default     = 5432
}

variable "iam_database_authentication_enabled" {
  description = "Specifies whether or not mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled"
  type        = bool
  default     = false
}

variable "manage_master_user_password" {
  description = "Set to true to allow RDS to manage the master user password in Secrets Manager"
  type        = bool
  default     = false
}

variable "master_user_secret_kms_key_id" {
  description = "The KMS key ID to encrypt the master user password secret"
  type        = string
  default     = null
}

# Network Configuration
variable "vpc_id" {
  description = "The ID of the VPC in which the RDS instance will be created"
  type        = string
}

variable "subnet_ids" {
  description = "A list of VPC subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "The AZ for the RDS instance"
  type        = string
  default     = null
}

variable "db_subnet_group_name" {
  description = "Name of DB subnet group. If not specified, it will create a new one"
  type        = string
  default     = null
}

# Security Group Configuration
variable "create_security_group" {
  description = "Whether to create security group for RDS instance"
  type        = bool
  default     = true
}

variable "security_group_rules" {
  description = "Map of security group rules to add to the security group created"
  type        = any
  default     = {}
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the RDS instance"
  type        = list(string)
  default     = []
}

variable "security_group_use_name_prefix" {
  description = "Whether to use name_prefix for the security group"
  type        = bool
  default     = true
}

variable "vpc_security_group_ids" {
  description = "List of VPC security groups to associate"
  type        = list(string)
  default     = []
}

# Maintenance Window
variable "maintenance_window" {
  description = "The window to perform maintenance in"
  type        = string
  default     = "sun:05:00-sun:07:00"
}

variable "backup_window" {
  description = "The daily time range during which automated backups are created"
  type        = string
  default     = "03:00-05:00"
}

variable "apply_immediately" {
  description = "Specifies whether any database modifications are applied immediately"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "The database can't be deleted when this value is set to true"
  type        = bool
  default     = false
}

variable "copy_tags_to_snapshot" {
  description = "Copy all tags from RDS database to snapshots"
  type        = bool
  default     = true
}

# Parameter Group
variable "parameters" {
  description = "A list of DB parameters to apply"
  type        = list(map(string))
  default     = []
}

variable "parameter_group_use_name_prefix" {
  description = "Whether to use name_prefix for the parameter group"
  type        = bool
  default     = true
}

variable "create_db_parameter_group" {
  description = "Whether to create a database parameter group"
  type        = bool
  default     = true
}

# Option Group
variable "create_db_option_group" {
  description = "Whether to create a database option group"
  type        = bool
  default     = true
}

variable "options" {
  description = "A list of Options to apply"
  type        = any
  default     = []
}

# Enhanced Monitoring
variable "create_monitoring_role" {
  description = "Create IAM role with a defined name that permits RDS to send enhanced monitoring metrics to CloudWatch Logs"
  type        = bool
  default     = true
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance"
  type        = number
  default     = 60
}

variable "monitoring_role_name" {
  description = "Name of the IAM role which will be created when create_monitoring_role is enabled"
  type        = string
  default     = null
}

variable "monitoring_role_use_name_prefix" {
  description = "Whether to use name_prefix for the monitoring IAM role"
  type        = bool
  default     = true
}

variable "monitoring_role_description" {
  description = "Description of the monitoring IAM role"
  type        = string
  default     = "Role for Enhanced Monitoring of RDS instance"
}

# Performance Insights
variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights are enabled"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "The amount of time in days to retain Performance Insights data"
  type        = number
  default     = 7
}

variable "performance_insights_kms_key_id" {
  description = "The ARN for the KMS key to encrypt Performance Insights data"
  type        = string
  default     = null
}

# CloudWatch Logs Exports
variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to enable for exporting to CloudWatch logs"
  type        = list(string)
  default     = ["postgresql", "upgrade"]
}

variable "create_cloudwatch_log_group" {
  description = "Determines whether a CloudWatch log group is created for each enabled_cloudwatch_logs_exports"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "The number of days to retain CloudWatch logs for the DB instance"
  type        = number
  default     = 30
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting log data"
  type        = string
  default     = null
}

# Backups and Replication
variable "replicate_source_db" {
  description = "Specifies the identifier of the source DB instance for a Read Replica"
  type        = string
  default     = null
}

variable "timeouts" {
  description = "Updated Terraform resource management timeouts"
  type        = map(string)
  default     = {}
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window"
  type        = bool
  default     = true
}

# Storage AutoScaling
variable "autoscaling_enabled" {
  description = "Whether to enable storage autoscaling"
  type        = bool
  default     = true
}

variable "autoscaling_max_capacity" {
  description = "Maximum Storage capacity for autoscaling"
  type        = number
  default     = 1000
}

variable "autoscaling_target_cpu" {
  description = "CPU target for autoscaling"
  type        = number
  default     = 70
}

variable "autoscaling_target_connections" {
  description = "Connections target for autoscaling"
  type        = number
  default     = null
}

variable "autoscaling_scale_in_cooldown" {
  description = "Scale-in cooldown period for autoscaling"
  type        = number
  default     = 300
}

variable "autoscaling_scale_out_cooldown" {
  description = "Scale-out cooldown period for autoscaling"
  type        = number
  default     = 300
}

variable "autoscaling_predefined_metric_type" {
  description = "Predefined metric type for autoscaling"
  type        = string
  default     = "RDSStorageSpaceUtilization"
}

# Blue/Green Deployments
variable "blue_green_update" {
  description = "Enables low-downtime updates using RDS Blue/Green deployments"
  type        = map(string)
  default     = {}
}

# Backups to S3
variable "s3_import" {
  description = "Restore from a Percona Xtrabackup in S3"
  type        = map(string)
  default     = null
}

# Custom CloudWatch Alarms
variable "create_cloudwatch_alarms" {
  description = "Whether to create CloudWatch alarms for the RDS instance"
  type        = bool
  default     = true
}

variable "cpu_utilization_threshold" {
  description = "The threshold for CPU utilization high alarm"
  type        = number
  default     = 80
}

variable "free_storage_space_threshold" {
  description = "The threshold for free storage space low alarm in bytes"
  type        = number
  default     = 5368709120 # 5GB in bytes
}

variable "database_connections_threshold" {
  description = "The threshold for database connections high alarm"
  type        = number
  default     = 100
}

variable "alarm_actions" {
  description = "The list of actions to execute when the alarm transitions into an ALARM state"
  type        = list(string)
  default     = []
}

# SSM Parameters
variable "store_password_in_ssm" {
  description = "Whether to store the database password in SSM Parameter Store"
  type        = bool
  default     = true
}

variable "store_connection_string_in_ssm" {
  description = "Whether to store the database connection string in SSM Parameter Store"
  type        = bool
  default     = true
}

variable "ssm_kms_key_id" {
  description = "The KMS key ID to use for SSM parameter encryption"
  type        = string
  default     = null
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}