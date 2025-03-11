# harbor-infrastructure/environments/dev/iam/terragrunt.hcl

include {
  path = find_in_parent_folders()
}

include "env" {
  path = find_in_parent_folders("dev_env.hcl")
  expose = true
  merge_strategy = "no_merge"
}

terraform {
  source = "../../../modules/iam"
}

inputs = {
  environment = include.env.inputs.environment
  
  admin_principals = [
    "arn:aws:iam::${include.env.inputs.aws_account_id}:root"  # For testing, use the account root
    # You can add more ARNs for actual administrators here
  ]
  
  operator_principals = [
    "arn:aws:iam::${include.env.inputs.aws_account_id}:root"  # For testing, use the account root
    # You can add more ARNs for operators here
  ]
  
  service_principals = [
    "arn:aws:iam::${include.env.inputs.aws_account_id}:root"  # For testing, use the account root
  ]
  
  # This will be updated with the actual S3 bucket ARN once it's created
  # For now, we use a placeholder that will need to be updated
  harbor_s3_bucket_arn = "arn:aws:s3:::harbor-artifacts-${include.env.inputs.environment}-${include.env.inputs.aws_account_id}"
  
  create_instance_profiles = false  # Set to true if you need EC2 instance profiles
  
  enable_cross_account_access = false  # Set to true for cross-account scenarios
  
  tags = {
    Project     = "Harbor-S2C2F"
    Environment = include.env.inputs.environment
    ManagedBy   = "Terragrunt"
  }
}

# Once the S3 bucket is created, we need to create a dependency on it
# For now, we comment this out since we're setting up the IAM module first
# dependency "s3" {
#   config_path = "../s3"
# }

# inputs = {
#   harbor_s3_bucket_arn = dependency.s3.outputs.s3_bucket_arn
# }