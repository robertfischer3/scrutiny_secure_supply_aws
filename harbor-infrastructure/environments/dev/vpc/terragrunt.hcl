include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/vpc"
}

inputs = {
  vpc_name             = "harbor-vpc-${get_terragrunt_dir()}" 
  enable_nat_gateway   = true
  single_nat_gateway   = get_env("TG_VAR_environment", "dev") != "prod" # Use multiple NAT gateways only in prod
  enable_dns_hostnames = true
  enable_dns_support   = true
  
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
      cidr_block  = "${get_env("TG_VAR_vpc_cidr", "10.0.0.0/16")}"
    }
  ]
}