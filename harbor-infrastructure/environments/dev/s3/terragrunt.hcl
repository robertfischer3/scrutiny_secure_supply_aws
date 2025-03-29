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

# Add this to generate a random suffix
generate "random" {
  path      = "random.tf"
  if_exists = "overwrite"
  contents  = <<EOF

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}
EOF
}

dependency "kms" {
  config_path = "../kms"
  skip_outputs = false
}

# Assume SNS topic exists
dependency "sns" {
  config_path = "../sns"
  skip_outputs = false
}

inputs = {
  # Add random suffix to bucket name to avoid conflicts
  bucket_name          = "harbor-artifacts-${include.env.inputs.environment}-${include.env.inputs.aws_account_id}-$${random_string.bucket_suffix.result}"
  force_destroy        = include.env.inputs.environment != "prod"
  versioning_enabled   = true
  
  # Encryption configuration
  sse_algorithm        = "aws:kms"
  kms_master_key_id    = dependency.kms.outputs.key_id
  bucket_key_enabled   = true
  
  # Security configurations
  block_public_access  = true
  require_tls          = true

  # Set to BucketOwnerEnforced to support notifications
  object_ownership     = include.env.inputs.object_ownership
  bucket_acl           = null
  
  # Lifecycle configuration
  lifecycle_rule_enabled = true
  lifecycle_expiration = {
    days = include.env.inputs.environment == "prod" ? 0 : 90
  }
  lifecycle_noncurrent_version_expiration = {
    days = include.env.inputs.environment == "prod" ? 365 : 30
  }
  
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
  
  # Uncomment and set to true when ready to enable notifications
  enable_security_notifications = true
  # Reference the SNS topic ARN
  notification_topic_arn = dependency.sns.outputs.topic_arn
  security_notification_prefix = "registry/"
  
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

# Include both dependencies
dependencies {
  paths = ["../kms", "../sns"]
}