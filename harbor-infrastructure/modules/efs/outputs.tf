# Outputs for efs module

# Module outputs will be defined here
output "id" {
  description = "The ID of the EFS file system"
  value       = aws_efs_file_system.this.id
}

output "arn" {
  description = "The ARN of the EFS file system"
  value       = aws_efs_file_system.this.arn
}

output "dns_name" {
  description = "The DNS name of the EFS file system"
  value       = aws_efs_file_system.this.dns_name
}

output "mount_targets" {
  description = "Map of mount targets created and their attributes"
  value       = { for idx, mt in aws_efs_mount_target.this : idx => {
    id              = mt.id
    file_system_id  = mt.file_system_id
    subnet_id       = mt.subnet_id
    ip_address      = mt.ip_address
    security_groups = mt.security_groups
  }}
}

output "security_group_id" {
  description = "The ID of the security group created for the EFS mount targets"
  value       = aws_security_group.efs.id
}

output "access_point_id" {
  description = "The ID of the EFS access point"
  value       = var.create_access_point ? aws_efs_access_point.this[0].id : null
}

output "access_point_arn" {
  description = "The ARN of the EFS access point"
  value       = var.create_access_point ? aws_efs_access_point.this[0].arn : null
}

output "access_point_posix_user" {
  description = "The POSIX user configuration of the EFS access point"
  value       = var.create_access_point ? aws_efs_access_point.this[0].posix_user : null
}

output "access_point_root_directory" {
  description = "The root directory configuration of the EFS access point"
  value       = var.create_access_point ? aws_efs_access_point.this[0].root_directory : null
}

output "replication_configuration_id" {
  description = "The ID of the EFS replication configuration"
  value       = var.enable_replication ? aws_efs_replication_configuration.this[0].id : null
}

output "replication_destination_file_system_id" {
  description = "The ID of the destination EFS file system"
  value       = var.enable_replication ? aws_efs_replication_configuration.this[0].destination[0].file_system_id : null
}

output "backup_plan_id" {
  description = "The ID of the backup plan"
  value       = var.create_backup_plan ? aws_backup_plan.this[0].id : null
}

output "backup_plan_arn" {
  description = "The ARN of the backup plan"
  value       = var.create_backup_plan ? aws_backup_plan.this[0].arn : null
}

output "backup_vault_id" {
  description = "The ID of the backup vault"
  value       = var.create_backup_plan ? aws_backup_vault.this[0].id : null
}

output "backup_vault_arn" {
  description = "The ARN of the backup vault"
  value       = var.create_backup_plan ? aws_backup_vault.this[0].arn : null
}

output "backup_role_arn" {
  description = "The ARN of the IAM role used for backups"
  value       = var.create_backup_plan ? aws_iam_role.backup[0].arn : null
}

output "encrypted" {
  description = "Whether the EFS file system is encrypted"
  value       = aws_efs_file_system.this.encrypted
}

output "kms_key_id" {
  description = "The ARN of the KMS key used to encrypt the EFS file system"
  value       = aws_efs_file_system.this.kms_key_id
}

output "performance_mode" {
  description = "The performance mode of the EFS file system"
  value       = aws_efs_file_system.this.performance_mode
}

output "throughput_mode" {
  description = "The throughput mode of the EFS file system"
  value       = aws_efs_file_system.this.throughput_mode
}

output "provisioned_throughput_in_mibps" {
  description = "The provisioned throughput in MiB/s of the EFS file system"
  value       = aws_efs_file_system.this.provisioned_throughput_in_mibps
}

output "lifecycle_policies" {
  description = "The lifecycle policies of the EFS file system"
  value       = try(aws_efs_file_system.this.lifecycle_policy, [])
}

output "size_in_bytes" {
  description = "The latest known metered size (in bytes) of data stored in the file system"
  value       = aws_efs_file_system.this.size_in_bytes
}

output "mount_target_dns_names" {
  description = "List of DNS names for the mount targets"
  value       = [for mt in aws_efs_mount_target.this : "${aws_efs_file_system.this.dns_name}:/${mt.subnet_id}"]
}

output "mount_commands" {
  description = "Commands to mount the EFS file system (one per subnet)"
  value       = [for mt in aws_efs_mount_target.this : "sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_file_system.this.dns_name}:/ /mnt/efs"]
}

output "cloudwatch_alarm_burst_credit_balance_arn" {
  description = "The ARN of the CloudWatch alarm for burst credit balance"
  value       = var.create_cloudwatch_alarms && var.throughput_mode == "bursting" ? aws_cloudwatch_metric_alarm.burst_credit_balance_low[0].arn : null
}

output "cloudwatch_alarm_percent_io_limit_arn" {
  description = "The ARN of the CloudWatch alarm for percent I/O limit"
  value       = var.create_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.percent_io_limit_high[0].arn : null
}