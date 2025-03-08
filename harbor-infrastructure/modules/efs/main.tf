resource "aws_efs_file_system" "this" {
  creation_token = var.name
  encrypted      = var.encrypted
  kms_key_id     = var.encrypted ? var.kms_key_id : null
  
  performance_mode                = var.performance_mode
  throughput_mode                 = var.throughput_mode
  provisioned_throughput_in_mibps = var.throughput_mode == "provisioned" ? var.provisioned_throughput_in_mibps : null
  
  lifecycle_policy {
    transition_to_ia = try(var.lifecycle_policy[0].transition_to_ia, null)
  }
  
  dynamic "lifecycle_policy" {
    for_each = length(var.lifecycle_policy) > 0 && lookup(var.lifecycle_policy[0], "transition_to_primary_storage_class", null) != null ? [1] : []
    content {
      transition_to_primary_storage_class = lookup(var.lifecycle_policy[0], "transition_to_primary_storage_class", null)
    }
  }
  
  # File system protection
  dynamic "lifecycle_policy" {
    for_each = var.enable_protection ? [1] : []
    content {
      transition_to_primary_storage_class = "AFTER_1_DAY"
    }
  }
  
  # Backup policy
  dynamic "backup_policy" {
    for_each = length(keys(var.backup_policy)) > 0 ? [var.backup_policy] : []
    content {
      status = backup_policy.value.status
    }
  }
  
  tags = merge(
    var.tags,
    {
      Name        = var.name
      Environment = var.environment
    }
  )
}

# Mount targets in each subnet
resource "aws_efs_mount_target" "this" {
  count = length(var.subnet_ids)
  
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = element(var.subnet_ids, count.index)
  security_groups = [aws_security_group.efs.id]
}

# Security group for EFS
resource "aws_security_group" "efs" {
  name        = "${var.name}-efs-sg"
  description = "Security group for EFS mount targets"
  vpc_id      = var.vpc_id
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.name}-efs-sg"
      Environment = var.environment
    }
  )
}

# Security group rules for EFS
resource "aws_security_group_rule" "ingress" {
  for_each = { for k, v in var.security_group_rules : k => v if length(var.security_group_rules) > 0 }
  
  security_group_id = aws_security_group.efs.id
  type              = "ingress"
  from_port         = lookup(each.value, "from_port", 2049)
  to_port           = lookup(each.value, "to_port", 2049)
  protocol          = lookup(each.value, "protocol", "tcp")
  description       = lookup(each.value, "description", "NFS traffic")
  
  cidr_blocks      = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks = lookup(each.value, "ipv6_cidr_blocks", null)
  prefix_list_ids  = lookup(each.value, "prefix_list_ids", null)
  self             = lookup(each.value, "self", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
}

# Allow all outbound traffic
resource "aws_security_group_rule" "egress" {
  security_group_id = aws_security_group.efs.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

# EFS Access Point for controlled access
resource "aws_efs_access_point" "this" {
  count = var.create_access_point ? 1 : 0
  
  file_system_id = aws_efs_file_system.this.id
  
  posix_user {
    gid = var.access_point_posix_user.gid
    uid = var.access_point_posix_user.uid
  }
  
  root_directory {
    path = var.access_point_root_directory.path
    creation_info {
      owner_gid   = var.access_point_root_directory.creation_info.owner_gid
      owner_uid   = var.access_point_root_directory.creation_info.owner_uid
      permissions = var.access_point_root_directory.creation_info.permissions
    }
  }
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.name}-access-point"
      Environment = var.environment
    }
  )
}

# Create a replication configuration for cross-region disaster recovery
resource "aws_efs_replication_configuration" "this" {
  count = var.enable_replication ? 1 : 0
  
  source_file_system_id = aws_efs_file_system.this.id
  
  destination {
    region = var.replication_destination_region
    
    # Use KMS encryption for the replicated data if KMS is enabled on source
    dynamic "kms_key_id" {
      for_each = var.encrypted && var.replication_kms_key_id != null ? [1] : []
      content {
        kms_key_id = var.replication_kms_key_id
      }
    }
  }
}

# Add automatic backups with AWS Backup if enabled
resource "aws_backup_selection" "this" {
  count = var.create_backup_plan ? 1 : 0
  
  name         = "${var.name}-backup-selection"
  iam_role_arn = aws_iam_role.backup[0].arn
  plan_id      = aws_backup_plan.this[0].id
  
  resources = [
    aws_efs_file_system.this.arn
  ]
  
  condition {
    string_equals {
      key   = "aws:ResourceTag/Environment"
      value = var.environment
    }
  }
}

resource "aws_backup_plan" "this" {
  count = var.create_backup_plan ? 1 : 0
  
  name = "${var.name}-backup-plan"
  
  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.this[0].name
    schedule          = var.backup_schedule
    
    lifecycle {
      delete_after = var.backup_retention_days
    }
    
    recovery_point_tags = {
      Environment = var.environment
      Name        = "${var.name}-backup"
    }
  }
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.name}-backup-plan"
      Environment = var.environment
    }
  )
}

resource "aws_backup_vault" "this" {
  count = var.create_backup_plan ? 1 : 0
  
  name        = "${var.name}-backup-vault"
  kms_key_arn = var.encrypted ? var.kms_key_id : null
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.name}-backup-vault"
      Environment = var.environment
    }
  )
}

resource "aws_iam_role" "backup" {
  count = var.create_backup_plan ? 1 : 0
  
  name = "${var.name}-backup-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.name}-backup-role"
      Environment = var.environment
    }
  )
}

resource "aws_iam_role_policy_attachment" "backup" {
  count = var.create_backup_plan ? 1 : 0
  
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup[0].name
}

# CloudWatch alarms for EFS monitoring
resource "aws_cloudwatch_metric_alarm" "burst_credit_balance_low" {
  count = var.create_cloudwatch_alarms && var.throughput_mode == "bursting" ? 1 : 0
  
  alarm_name          = "${var.name}-burst-credit-balance-low"
  alarm_description   = "Alarm when EFS burst credit balance is low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "BurstCreditBalance"
  namespace           = "AWS/EFS"
  period              = 300
  statistic           = "Average"
  threshold           = var.burst_credit_balance_threshold
  
  dimensions = {
    FileSystemId = aws_efs_file_system.this.id
  }
  
  alarm_actions = var.alarm_actions
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.name}-burst-credit-balance-low"
      Environment = var.environment
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "percent_io_limit_high" {
  count = var.create_cloudwatch_alarms ? 1 : 0
  
  alarm_name          = "${var.name}-percent-io-limit-high"
  alarm_description   = "Alarm when EFS percent I/O limit is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "PercentIOLimit"
  namespace           = "AWS/EFS"
  period              = 300
  statistic           = "Average"
  threshold           = var.percent_io_limit_threshold
  
  dimensions = {
    FileSystemId = aws_efs_file_system.this.id
  }
  
  alarm_actions = var.alarm_actions
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.name}-percent-io-limit-high"
      Environment = var.environment
    }
  )
}