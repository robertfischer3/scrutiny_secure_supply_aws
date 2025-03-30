include {
  path = find_in_parent_folders()
}

include "env" {
  path = find_in_parent_folders("dev_env.hcl")
  expose = true
  merge_strategy = "no_merge"
}

terraform {
  source = "../../../modules/s3"
}

dependency "kms" {
  config_path = "../kms"
  skip_outputs = false
}

inputs = {
  bucket_name          = "harbor-artifacts-${include.env.inputs.environment}-${include.env.inputs.aws_account_id}"
  force_destroy        = include.env.inputs.environment != "prod"
  versioning_enabled   = true
  
  # Encryption configuration
  sse_algorithm        = "aws:kms"
  kms_master_key_id    = dependency.kms.outputs.key_id
  kms_master_key_arn   = dependency.kms.outputs.key_arn
  bucket_key_enabled   = true
  
  # Security configurations
  block_public_access  = true
  require_tls          = true
  object_ownership     = "BucketOwnerEnforced"
  
  # Lifecycle configuration
  lifecycle_rule_enabled = true
  lifecycle_expiration = {
    days = include.env.inputs.environment == "prod" ? 0 : 90  # 0 means never expire in prod
  }
  lifecycle_noncurrent_version_expiration = {
    days = include.env.inputs.environment == "prod" ? 365 : 30
  }
  lifecycle_transitions = [
    {
      days          = 30
      storage_class = "STANDARD_IA"
    },
    {
      days          = 60
      storage_class = "GLACIER"
    }
  ]
  
  # CORS configuration
  enable_cors = true
  cors_rule = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
      allowed_origins = ["https://${include.env.inputs.harbor_domain}"]
      max_age_seconds = 3000
    }
  ]
  
  # Access logging
  enable_access_logging = true
  access_log_bucket_name = "harbor-logs-${include.env.inputs.environment}-${include.env.inputs.aws_account_id}"
  access_log_prefix      = "s3-access-logs/"
  
  # Intelligent tiering for cost optimization
  intelligent_tiering_enabled = include.env.inputs.environment == "prod"
  intelligent_tiering_prefix = "registry/"
  intelligent_tiering_archive_days = 90
  intelligent_tiering_deep_archive_days = 180
  
  # Security notifications
  enable_security_notifications = false
  notification_topic_arn = "arn:aws:sns:${include.env.inputs.aws_region}:${include.env.inputs.aws_account_id}:harbor-security-notifications"
  security_notification_prefix = "registry/"
  
  # Cross-region replication (for prod only)
  enable_replication = include.env.inputs.environment == "prod"
  replication_destination_bucket_arn = include.env.inputs.environment == "prod" ? "arn:aws:s3:::harbor-artifacts-prod-dr-${include.env.inputs.aws_account_id}" : ""
  replication_region = "us-east-1"  # DR region
  replication_storage_class = "STANDARD_IA"
  
  # Inventory reporting
  enable_inventory = include.env.inputs.environment == "prod"
  inventory_destination_bucket_arn = include.env.inputs.environment == "prod" ? "arn:aws:s3:::harbor-inventory-${include.env.inputs.aws_account_id}" : ""
  inventory_destination_prefix = "bucket-inventory/"
  
  # AWS Region
  aws_region = include.env.inputs.aws_region
  
  # Tags
  tags = {
    Environment = include.env.inputs.environment
    Project     = "Harbor-S2C2F"
    ManagedBy   = "Terragrunt"
    Service     = "Container Registry"
    Component   = "Storage"
  }
}

# Explicitly state that this module cannot be created until KMS is ready
dependencies {
  paths = ["../kms"]
}