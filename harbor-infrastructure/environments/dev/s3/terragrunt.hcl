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

# Generate a shorter bucket name
locals {
  # Use a shorter prefix and truncate the account ID
  account_suffix = substr(include.env.inputs.aws_account_id, -6, -1)
  bucket_name = "harbor-${include.env.inputs.environment}-${local.account_suffix}"
}

inputs = {
  bucket_name          = local.bucket_name
  force_destroy        = include.env.inputs.environment != "prod"
  versioning_enabled   = true
  
  # Encryption configuration
  sse_algorithm        = "aws:kms"
  kms_master_key_id    = dependency.kms.outputs.key_id
  bucket_key_enabled   = true
  
  # Security configurations
  block_public_access  = true
  require_tls          = true
  object_ownership     = include.env.inputs.object_ownership
  
  # Other S3 configurations as needed
  # Note: No notification configuration here
  
  # Tags
  tags = {
    Environment = include.env.inputs.environment
    Project     = "Harbor-S2C2F"
    ManagedBy   = "Terragrunt"
    Service     = "Container Registry"
    Component   = "Storage"
  }
}

dependencies {
  paths = ["../kms"]
}