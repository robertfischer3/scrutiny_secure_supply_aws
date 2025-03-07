include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/efs"
}

inputs = {
  name                    = "harbor-efs-${local.environment}"
  encrypted               = true
  kms_key_id              = dependency.kms.outputs.key_arn
  performance_mode        = "generalPurpose"
  throughput_mode         = "bursting"
  vpc_id                  = dependency.vpc.outputs.vpc_id
  subnet_ids              = dependency.vpc.outputs.private_subnets
  security_group_rules = {
    ingress = {
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      cidr_blocks = dependency.vpc.outputs.private_subnets_cidr_blocks
      description = "NFS from private subnets"
    }
  }
  
  # Lifecycle policy - transition files to IA after 30 days
  lifecycle_policy = [{
    transition_to_ia = "AFTER_30_DAYS"
  }]
  
  # Backup policy
  backup_policy = {
    status = "ENABLED"
  }
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "kms" {
  config_path = "../kms"
}