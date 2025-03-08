module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 5.0"

  identifier = var.identifier

  # Database engine configuration
  engine               = var.engine
  engine_version       = var.engine_version
  family               = var.family != null ? var.family : local.default_family
  major_engine_version = var.major_engine_version
  instance_class       = var.instance_class

  # Database storage configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = var.storage_encrypted
  storage_type          = var.storage_type
  kms_key_id            = var.kms_key_id

  # Database authentication
  db_name                     = var.db_name
  username                    = var.username
  password                    = var.password
  port                        = var.port
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  manage_master_user_password = var.manage_master_user_password
  master_user_secret_kms_key_id = var.manage_master_user_password ? var.master_user_secret_kms_key_id : null

  # Network configuration
  vpc_id                = var.vpc_id
  subnet_ids            = var.subnet_ids
  multi_az              = var.multi_az
  db_subnet_group_name  = var.db_subnet_group_name
  create_db_subnet_group = var.db_subnet_group_name == null

  # Security Group configuration
  create_security_group = var.create_security_group
  security_group_rules  = var.security_group_rules
  allowed_cidr_blocks   = var.allowed_cidr_blocks
  security_group_use_name_prefix = var.security_group_use_name_prefix
  vpc_security_group_ids = var.create_security_group ? [] : var.vpc_security_group_ids

  # Maintenance window
  maintenance_window    = var.maintenance_window
  backup_window         = var.backup_window
  apply_immediately     = var.apply_immediately
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot   = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final-snapshot-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  deletion_protection   = var.deletion_protection
  copy_tags_to_snapshot = var.copy_tags_to_snapshot

  # Parameter group
  parameters       = var.parameters
  parameter_group_use_name_prefix = var.parameter_group_use_name_prefix
  create_db_parameter_group = var.create_db_parameter_group

  # Option group
  create_db_option_group = var.create_db_option_group
  options               = var.options

  # Enhanced monitoring
  create_monitoring_role  = var.create_monitoring_role
  monitoring_interval     = var.monitoring_interval
  monitoring_role_name    = var.monitoring_role_name
  monitoring_role_use_name_prefix = var.monitoring_role_use_name_prefix
  monitoring_role_description = var.monitoring_role_description

  # Performance Insights
  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  performance_insights_kms_key_id = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null

  # CloudWatch Logs exports
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  create_cloudwatch_log_group = var.create_cloudwatch_log_group
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id = var.cloudwatch_log_group_kms_key_id

  # Backup and replication
  replicate_source_db   = var.replicate_source_db
  timeouts              = var.timeouts
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  # Storage AutoScaling
  autoscaling_enabled    = var.autoscaling_enabled
  autoscaling_max_capacity = var.autoscaling_max_capacity
  autoscaling_target_cpu  = var.autoscaling_target_cpu
  autoscaling_target_connections = var.autoscaling_target_connections
  autoscaling_scale_in_cooldown = var.autoscaling_scale_in_cooldown
  autoscaling_scale_out_cooldown = var.autoscaling_scale_out_cooldown
  autoscaling_predefined_metric_type = var.autoscaling_predefined_metric_type
  
  # Blue/Green deployments
  blue_green_update = var.blue_green_update

  # High availability
  availability_zone = var.multi_az ? null : var.availability_zone

  # Backups to S3
  s3_import = var.s3_import

  # Tags
  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Terraform   = "true"
      Module      = "harbor-rds"
    }
  )
}

# Create an SSM parameter to store the database password (when not using secrets manager)
resource "aws_ssm_parameter" "db_password" {
  count = var.store_password_in_ssm && !var.manage_master_user_password ? 1 : 0
  
  name        = "/harbor/${var.environment}/database/${var.identifier}/password"
  description = "Master password for ${var.identifier} RDS instance"
  type        = "SecureString"
  value       = var.password
  key_id      = var.ssm_kms_key_id
  
  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Terraform   = "true"
      Module      = "harbor-rds"
    }
  )
}

# Create an SSM parameter to store the database connection string
resource "aws_ssm_parameter" "db_connection_string" {
  count = var.store_connection_string_in_ssm ? 1 : 0
  
  name        = "/harbor/${var.environment}/database/${var.identifier}/connection_string"
  description = "Connection string for ${var.identifier} RDS instance"
  type        = "SecureString"
  value       = local.connection_string
  key_id      = var.ssm_kms_key_id
  
  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Terraform   = "true"
      Module      = "harbor-rds"
    }
  )
}

# Create a CloudWatch alarm for high CPU utilization
resource "aws_cloudwatch_metric_alarm" "cpu_utilization_high" {
  count = var.create_cloudwatch_alarms ? 1 : 0
  
  alarm_name          = "${var.identifier}-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_utilization_threshold
  alarm_description   = "Average database CPU utilization is high"
  
  dimensions = {
    DBInstanceIdentifier = module.db.db_instance_id
  }
  
  alarm_actions = var.alarm_actions
  
  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Terraform   = "true"
      Module      = "harbor-rds"
    }
  )
}

# Create a CloudWatch alarm for low free storage space
resource "aws_cloudwatch_metric_alarm" "free_storage_space_low" {
  count = var.create_cloudwatch_alarms ? 1 : 0
  
  alarm_name          = "${var.identifier}-low-free-storage-space"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.free_storage_space_threshold
  alarm_description   = "Average database free storage space is low"
  
  dimensions = {
    DBInstanceIdentifier = module.db.db_instance_id
  }
  
  alarm_actions = var.alarm_actions
  
  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Terraform   = "true"
      Module      = "harbor-rds"
    }
  )
}

# Create a CloudWatch alarm for high database connections
resource "aws_cloudwatch_metric_alarm" "database_connections_high" {
  count = var.create_cloudwatch_alarms ? 1 : 0
  
  alarm_name          = "${var.identifier}-high-database-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.database_connections_threshold
  alarm_description   = "Average database connections are high"
  
  dimensions = {
    DBInstanceIdentifier = module.db.db_instance_id
  }
  
  alarm_actions = var.alarm_actions
  
  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Terraform   = "true"
      Module      = "harbor-rds"
    }
  )
}

# Locals for module
locals {
  default_family = var.engine == "postgres" ? "postgres${split(".", var.engine_version)[0]}" : null
  
  connection_string = var.engine == "postgres" ? "postgresql://${var.username}:${var.password}@${module.db.db_instance_address}:${var.port}/${var.db_name}" : null
}