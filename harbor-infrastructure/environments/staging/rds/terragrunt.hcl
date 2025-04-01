include {
  path = find_in_parent_folders()
}

include "env" {
  path = find_in_parent_folders("dev_env.hcl")
  expose = true
  merge_strategy = "no_merge"
}

terraform {
  source = "../../../modules/rds"
}

dependency "vpc" {
  config_path = "../vpc"
  skip_outputs = false
}

dependency "kms" {
  config_path = "../kms"
  skip_outputs = false
}

inputs = {
  # Basic settings
  identifier           = "harbor-db-${include.env.inputs.environment}"
  engine               = "postgres"
  engine_version       = "15.3"
  instance_class       = include.env.inputs.environment == "prod" ? "db.m5.large" : "db.t3.medium"
  allocated_storage    = include.env.inputs.environment == "prod" ? 100 : 20
  max_allocated_storage = include.env.inputs.environment == "prod" ? 1000 : 100
  
  # Database access configuration
  db_name              = "registry"
  username             = "harboradmin"
  password             = "PLACEHOLDER_TO_BE_CHANGED_BEFORE_APPLY"  # Use AWS Secrets Manager in actual deployment
  port                 = 5432
  
  # Network configuration
  vpc_id               = dependency.vpc.outputs.vpc_id
  subnet_ids           = dependency.vpc.outputs.database_subnets != null ? dependency.vpc.outputs.database_subnets : dependency.vpc.outputs.private_subnets
  
  # High availability configuration
  multi_az             = include.env.inputs.environment == "prod"
  deletion_protection  = include.env.inputs.environment == "prod"
  skip_final_snapshot  = include.env.inputs.environment != "prod"
  
  # Storage configuration
  storage_encrypted    = true
  kms_key_id           = dependency.kms.outputs.key_arn
  storage_type         = "gp3"
  
  # Backup configuration
  backup_retention_period = include.env.inputs.environment == "prod" ? 30 : 7
  backup_window           = "03:00-05:00"
  maintenance_window      = "sun:05:00-sun:07:00"
  
  # Logging configuration
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group = true
  cloudwatch_log_group_retention_in_days = include.env.inputs.environment == "prod" ? 90 : 30
  
  # Security group rules
  security_group_rules = {
    ingress = {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = dependency.vpc.outputs.private_subnets_cidr_blocks
      description = "PostgreSQL from private subnets"
    }
  }
  
  # Parameter group settings
  parameters = [
    {
      name  = "log_statement"
      value = "all"
    },
    {
      name  = "log_min_duration_statement"
      value = "1000"  # Log queries taking more than 1 second
    },
    {
      name  = "log_connections"
      value = "1"
    },
    {
      name  = "log_disconnections"
      value = "1"
    },
    {
      name  = "log_lock_waits"
      value = "1"
    },
    {
      name  = "log_temp_files"
      value = "0"
    }
  ]
  
  # Performance Insights
  performance_insights_enabled = true
  performance_insights_retention_period = include.env.inputs.environment == "prod" ? 731 : 7
  
  # Enhanced monitoring
  monitoring_interval = include.env.inputs.environment == "prod" ? 30 : 60
  create_monitoring_role = true
  
  # Auto minor version upgrade
  auto_minor_version_upgrade = true
  
  # Storage AutoScaling
  autoscaling_enabled = true
  autoscaling_max_capacity = include.env.inputs.environment == "prod" ? 1000 : 100
  autoscaling_target_cpu = 70
  
  # CloudWatch alarms
  create_cloudwatch_alarms = true
  cpu_utilization_threshold = 80
  free_storage_space_threshold = 5368709120  # 5GB in bytes
  database_connections_threshold = include.env.inputs.environment == "prod" ? 100 : 50
  
  # SSM Parameters
  store_password_in_ssm = true
  store_connection_string_in_ssm = true
  
  # Tags
  tags = {
    Environment = include.env.inputs.environment
    Project     = "Harbor-S2C2F"
    ManagedBy   = "Terragrunt"
    Service     = "Container Registry"
    Component   = "Database"
  }
}

# This module cannot be created until dependencies are ready
dependencies {
  paths = ["../vpc", "../kms"]
}