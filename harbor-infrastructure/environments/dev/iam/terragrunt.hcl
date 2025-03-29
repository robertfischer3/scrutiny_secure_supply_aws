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
    "arn:aws:iam::${include.env.inputs.aws_account_id}:root"
  ]
  
  operator_principals = [
    "arn:aws:iam::${include.env.inputs.aws_account_id}:root"
  ]
  
  service_principals = [
    "arn:aws:iam::${include.env.inputs.aws_account_id}:root"
  ]
  
  # Use a placeholder ARN instead of referring to the actual S3 bucket
  harbor_s3_bucket_arn = "arn:aws:s3:::harbor-artifacts-${include.env.inputs.environment}-${include.env.inputs.aws_account_id}-placeholder"
  
  create_instance_profiles = false
  enable_cross_account_access = false
  
  tags = {
    Project     = "Harbor-S2C2F"
    Environment = include.env.inputs.environment
    ManagedBy   = "Terragrunt"
  }
}

# Remove the dependency on S3
# dependencies {
#   paths = ["../s3"]
# }