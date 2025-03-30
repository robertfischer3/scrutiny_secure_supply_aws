include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/efs"
}

inputs = {
  name                    = "harbor-efs-${include.env.inputs.environment}"
  encrypted               = true
  kms_key_id              = dependency.kms.outputs.key_arn
  performance_mode        = "generalPurpose"
  throughput_mode         = "bursting"
  
  # Enhanced security group rules
  security_group_rules = {
    ingress_eks = {
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      source_security_group_id = dependency.eks.outputs.node_security_group_id
      description = "NFS from EKS nodes only"
    }
  }
  
  # Create a default access point with least privilege
  create_access_point = true
  access_point_posix_user = {
    gid = 1000
    uid = 1000
  }
  access_point_root_directory = {
    path = "/harbor"
    creation_info = {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "0755"
    }
  }
  
  lifecycle_policy = [
    {
      transition_to_ia = "AFTER_30_DAYS"
    },
    {
      transition_to_primary_storage_class = "AFTER_1_ACCESS"
    }
  ]

   # CloudWatch alarms
  create_cloudwatch_alarms = true
  burst_credit_balance_threshold = 1000000000 # 1GB
  percent_io_limit_threshold = 70
  alarm_actions = [dependency.sns.outputs.topic_arn]
  
  # Backup policies
  create_backup_plan = true
  backup_schedule = "cron(0 1 * * ? *)"
  backup_retention_days = include.env.inputs.environment == "prod" ? 90 : 30
  
  # Add S2C2F tags
  tags = {
    Environment = include.env.inputs.environment
    Project     = "Harbor-S2C2F"
    ManagedBy   = "Terragrunt"
    Compliance  = "S2C2F-Level3"
    Component   = "Storage"
    DataClass   = "Restricted"
  }

  # Backup policy
  backup_policy = {
    status = "ENABLED"
  }
}

dependency "vpc" {
  config_path = "../vpc"
  skip_outputs = false
}

dependency "kms" {
  config_path = "../kms"
  skip_outputs = false
}

# Explicitly state that this module cannot be created until dependencies are ready
dependencies {
  paths = ["../vpc", "../kms"]
}
