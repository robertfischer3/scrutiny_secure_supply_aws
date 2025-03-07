include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/vpc"
}

inputs = {
  vpc_name             = "harbor-vpc-${local.environment}"
  enable_nat_gateway   = true
  single_nat_gateway   = local.environment != "prod" # Use multiple NAT gateways only in prod
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
      cidr_block  = local.vpc_cidr
    }
  ]
}