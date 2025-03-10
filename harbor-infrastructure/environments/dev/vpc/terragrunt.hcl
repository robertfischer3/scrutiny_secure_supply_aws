include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path = find_in_parent_folders("dev_env.hcl")
  expose = true
  merge_strategy = "no_merge"

}

terraform {
  source = "../../../modules/vpc"
}


inputs = {
  vpc_name             = "harbor-vpc-${include.env.inputs.environment}"
  availability_zones   = include.env.inputs.availability_zones
  private_subnets      = include.env.inputs.private_subnets
  public_subnets       = include.env.inputs.public_subnets
  environment          = include.env.inputs.environment

  enable_nat_gateway   = true
  single_nat_gateway   = include.env.inputs.environment != "prod" # Use multiple NAT gateways only in prod
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  # VPC endpoints for AWS services
  enable_s3_endpoint          = true
  enable_ecr_api_endpoint     = true
  enable_ecr_dkr_endpoint     = true
  enable_kms_endpoint         = true
  enable_secretsmanager_endpoint = true
  
  # NACL rules for additional security
  public_inbound_acl_rules  = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
    },
    {
      rule_number = 110
      rule_action = "allow"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
    }
  ]
  private_inbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = include.env.inputs.vpc_cidr
    }
  ]
}
