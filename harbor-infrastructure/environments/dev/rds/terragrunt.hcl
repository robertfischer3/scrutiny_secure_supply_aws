include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/rds"
}

inputs = {
  identifier           = "harbor-db-${local.environment}"
  engine               = "postgres"
  engine_version       = "15.3"
  instance_class       = local.environment == "prod" ? "db.m5.large" : "db.t3.medium"
  allocated_storage    = local.environment == "prod" ? 100 : 20
  max_allocated_storage = local.environment == "prod" ? 1000 : 100
  db_name              = "registry"
  username             = "harboradmin"
  password             = "PLACEHOLDER_TO_BE_CHANGED_BEFORE_APPLY"  # Use AWS Secrets Manager in actual deployment
  port                 = 5432
  
  vpc_id               = dependency.vpc.outputs.vpc_id
  subnet_ids           = dependency.vpc.outputs.private_subnets
  
  multi_az             = local.environment == "prod"
  deletion_protection  = local.environment == "prod"
  skip_final_snapshot  = local.environment != "prod"
  
  storage_encrypted    = true
  kms_key_id           = dependency.kms.outputs.key_arn
  
  backup_retention_period = local.environment == "prod" ? 30 : 7
  backup_window           = "03:00-05:00"
  maintenance_window      = "sun:05:00-sun:07:00"
  
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  
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
    }
  ]
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
