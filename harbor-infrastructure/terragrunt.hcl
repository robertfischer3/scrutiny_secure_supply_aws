
generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}
EOF
}

locals {
  # Extract environment from the directory path
  environment = get_env("scrutiny_harbor_environment_name")
  region      = get_env("scrutiny_harbor_aws_region")
  aws_account_id = get_aws_account_id()
}