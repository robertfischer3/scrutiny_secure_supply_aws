output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.db.db_instance_address
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.db.db_instance_arn
}

output "db_instance_availability_zone" {
  description = "The availability zone of the RDS instance"
  value       = module.db.db_instance_availability_zone
}

output "db_instance_endpoint" {
  description = "The connection endpoint of the RDS instance"
  value       = module.db.db_instance_endpoint
}

output "db_instance_engine" {
  description = "The database engine of the RDS instance"
  value       = module.db.db_instance_engine
}

output "db_instance_engine_version_actual" {
  description = "The running version of the database engine"
  value       = module.db.db_instance_engine_version_actual
}

output "db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = module.db.db_instance_hosted_zone_id
}

output "db_instance_id" {
  description = "The RDS instance ID"
  value       = module.db.db_instance_id
}

output "db_instance_resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = module.db.db_instance_resource_id
}

output "db_instance_status" {
  description = "The RDS instance status"
  value       = module.db.db_instance_status
}

output "db_instance_name" {
  description = "The database name"
  value       = module.db.db_instance_name
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = module.db.db_instance_username
  sensitive   = true
}

output "db_instance_port" {
  description = "The database port"
  value       = module.db.db_instance_port
}

output "db_instance_ca_cert_identifier" {
  description = "Specifies the identifier of the CA certificate for the DB instance"
  value       = module.db.db_instance_ca_cert_identifier
}

output "db_instance_domain" {
  description = "The ID of the Directory Service Active Directory domain the instance is joined to"
  value       = module.db.db_instance_domain
}

output "db_instance_domain_iam_role_name" {
  description = "The name of the IAM role to be used when making API calls to the Directory Service"
  value       = module.db.db_instance_domain_iam_role_name
}

output "db_instance_password" {
  description = "The database password"
  value       = var.password
  sensitive   = true
}

output "db_instance_master_user_secret_arn" {
  description = "The ARN of the master user secret (Only available when manage_master_user_password is set to true)"
  value       = module.db.db_instance_master_user_secret_arn
}

output "db_subnet_group_id" {
  description = "The db subnet group name"
  value       = module.db.db_subnet_group_id
}

output "db_subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = module.db.db_subnet_group_arn
}

output "db_parameter_group_id" {
  description = "The db parameter group id"
  value       = module.db.db_parameter_group_id
}

output "db_parameter_group_arn" {
  description = "The ARN of the db parameter group"
  value       = module.db.db_parameter_group_arn
}

output "db_option_group_id" {
  description = "The db option group id"
  value       = module.db.db_option_group_id
}

output "db_option_group_arn" {
  description = "The ARN of the db option group"
  value       = module.db.db_option_group_arn
}

output "db_enhanced_monitoring_iam_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the enhanced monitoring role"
  value       = module.db.enhanced_monitoring_iam_role_arn
}

output "db_instance_cloudwatch_log_groups" {
  description = "Map of CloudWatch log groups created and their attributes"
  value       = module.db.db_instance_cloudwatch_log_groups
}

output "db_security_group_id" {
  description = "The security group ID of the RDS instance"
  value       = module.db.security_group_id
}

output "db_connection_string" {
  description = "The connection string for connecting to the RDS instance"
  value       = local.connection_string
  sensitive   = true
}

output "db_password_ssm_parameter_name" {
  description = "The name of the SSM parameter storing the database password"
  value       = var.store_password_in_ssm && !var.manage_master_user_password ? aws_ssm_parameter.db_password[0].name : null
}

output "db_connection_string_ssm_parameter_name" {
  description = "The name of the SSM parameter storing the database connection string"
  value       = var.store_connection_string_in_ssm ? aws_ssm_parameter.db_connection_string[0].name : null
}

output "db_instance_identifier" {
  description = "The identifier of the RDS instance"
  value       = var.identifier
}

output "cloudwatch_alarm_cpu_arn" {
  description = "The ARN of the CloudWatch alarm for high CPU utilization"
  value       = var.create_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.cpu_utilization_high[0].arn : null
}

output "cloudwatch_alarm_storage_arn" {
  description = "The ARN of the CloudWatch alarm for low free storage space"
  value       = var.create_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.free_storage_space_low[0].arn : null
}

output "cloudwatch_alarm_connections_arn" {
  description = "The ARN of the CloudWatch alarm for high database connections"
  value       = var.create_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.database_connections_high[0].arn : null
}