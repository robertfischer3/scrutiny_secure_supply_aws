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

inputs = {
  identifier           = "harbor-db-${include.env.inputs.environment}"
  engine               = "postgres"
  engine_version       = "15.3"
  instance_class       = include.env.inputs.environment == "prod" ? "db.m5.large" : "db.t3.medium"
  allocated_storage    = include.env.inputs.environment == "prod" ? 100 : 20
  max_allocated_storage = include.env.inputs.environment == "prod" ? 1000 : 100
  
  # Enhanced security - use SSM or Secrets Manager
  username             = "harboradmin"
  manage_master_user_password = true  # Use AWS Secrets Manager
  
  # Network security
  vpc_id               = dependency.vpc.outputs.vpc_id
  subnet_ids           = dependency.vpc.outputs.database_subnets  # Use dedicated DB subnets
  multi_az             = include.env.inputs.environment == "prod"
  deletion_protection  = include.env.inputs.environment == "prod"
  
  # Enhanced encryption
  storage_encrypted    = true
  kms_key_id           = dependency.kms.outputs.key_arn
  
  # Enhanced backup policies
  backup_retention_period = include.env.inputs.environment == "prod" ? 35 : 7
  copy_tags_to_snapshot  = true
  backup_window           = "03:00-05:00"
  maintenance_window      = "sun:05:00-sun:07:00"
  
  # Enhanced logging
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade", "alert", "listener"]
  
  # Enhanced security group rules - restrict to EKS only
  security_group_rules = {
    ingress_eks = {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      source_security_group_id = dependency.eks.outputs.node_security_group_id
      description = "PostgreSQL from EKS nodes only"
    }
  }
  
  # Enhanced parameter group settings for security
  parameters = [
    {
      name  = "log_statement"
      value = "all"
    },
    {
      name  = "log_min_duration_statement"
      value = "1000"
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
      name  = "password_encryption"
      value = "scram-sha-256"
    },
    {
      name  = "ssl"
      value = "1"
    },
    {
      name = "rds.force_ssl"
      value = "1"
    }
  ]
  
  # Enhanced monitoring
  monitoring_interval = 15  # Seconds
  create_monitoring_role = true
  
  # Performance Insights
  performance_insights_enabled = true
  performance_insights_retention_period = 731  # Days (maximum)
  
  # Enhanced CloudWatch alarms
  create_cloudwatch_alarms = true
  cpu_utilization_threshold = 70
  free_storage_space_threshold = 10737418240  # 10GB in bytes
  database_connections_threshold = 80
  alarm_actions = [dependency.sns.outputs.topic_arn]
  
  # Store credentials in SSM Parameter Store
  store_password_in_ssm = true
  store_connection_string_in_ssm = true
  
  # S2C2F tags
  tags = {
    Environment = include.env.inputs.environment
    Project     = "Harbor-S2C2F"
    ManagedBy   = "Terragrunt"
    Compliance  = "S2C2F-Level3"
    Component   = "Database"
    DataClass   = "Restricted"
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
