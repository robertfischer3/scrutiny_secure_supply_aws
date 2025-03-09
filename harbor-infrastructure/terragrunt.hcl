# harbor-infrastructure/terragrunt.hcl (simplified)
remote_state {
  backend = "s3"
  generate = {
    path = "harbor_terragrunt_generated_state.tf"
    if_exists = "overwrite"
  }
  
  config = {
    bucket         = "harbor-terraform-state-${local.aws_account_id}-${local.environment}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = "harbor-terraform-locks"
  }
}

generate "provider" {
  path      = "harbor-terragrunt-generated-provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region}"
  
  default_tags {
    tags = {
      Environment = "${local.environment}"
      Project     = "Harbor-S2C2F"
      ManagedBy   = "Terraform"
    }
  }
}
EOF
}

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