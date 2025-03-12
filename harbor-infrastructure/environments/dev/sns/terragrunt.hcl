include {
  path = find_in_parent_folders()
}

include "env" {
  path = find_in_parent_folders("dev_env.hcl")
  expose = true
  merge_strategy = "no_merge"
}

terraform {
  source = "../../../modules/sns"
}

dependency "kms" {
  config_path = "../kms"
  skip_outputs = false
}

inputs = {
  environment    = include.env.inputs.environment
  topic_name     = "harbor-security-notifications-${include.env.inputs.environment}"
  display_name   = "Harbor Security Notifications"
  kms_key_id     = dependency.kms.outputs.key_id
  
  # This is initially empty and will be updated later with the S3 bucket ARN
  # after the circular dependency is resolved
  s3_bucket_arns = []
  
  # Add any email addresses that should receive notifications
  email_subscriptions = []
  
  # Tags
  tags = {
    Project     = "Harbor-S2C2F"
    Environment = include.env.inputs.environment
    ManagedBy   = "Terragrunt"
    Component   = "Notifications"
  }
}

# Explicitly state that this module depends on KMS
dependencies {
  paths = ["../kms"]
}