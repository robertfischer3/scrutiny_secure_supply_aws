# Environment-level variables for dev
locals {
  environment = "dev"
  
  # Network configuration
  vpc_cidr            = "10.0.0.0/16"
  availability_zones  = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets      = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  # EKS configuration
  cluster_name        = "harbor-${local.environment}"
  kubernetes_version  = "1.28"
  node_instance_types = ["m5.large"]
  aws_region = get_env("scrutiny_harbor_aws_region")
  
  # Harbor configuration
  harbor_domain       = "harbor-${local.environment}.scrutiny-harbor.com"
  harbor_namespace    = "harbor"

  is_testing_mode     = true # Set to true to enable deletion protection for KMS key
  deletion_window_in_days = 7 # Reduced to 7 days for dev purposes

   # Only create a new key if not in testing mode or if the key doesn't exist
  create_new_key               = false
  
  # When testing, try to use an existing key with this prefix if available
  reuse_existing_key_prefix    = "harbor-keys-${local.environment}"
  aws_account_id = get_aws_account_id()

  key_administrators = ["arn:aws:iam::${local.aws_account_id}:role/HarborAdmin-${local.environment}", "arn:aws:iam::${local.aws_account_id}:role/HarborKMSAdmin-${local.environment}"]
  key_users = ["arn:aws:iam::${local.aws_account_id}:role/HarborKMSUser-${local.environment}"]

  key_usage = "ENCRYPT_DECRYPT"
}

inputs = {
  environment         = local.environment
  vpc_cidr            = local.vpc_cidr
  availability_zones  = local.availability_zones
  private_subnets     = local.private_subnets
  public_subnets      = local.public_subnets
  cluster_name        = local.cluster_name
  kubernetes_version  = local.kubernetes_version
  node_instance_types = local.node_instance_types
  harbor_domain       = local.harbor_domain
  harbor_namespace    = local.harbor_namespace
  create_new_key      = local.create_new_key
  reuse_existing_key_prefix = local.reuse_existing_key_prefix
  is_testing_mode     = local.is_testing_mode
  aws_account_id      = local.aws_account_id
  deletion_window_in_days = local.deletion_window_in_days
  enable_key_rotation = true
  key_usage           = local.key_usage
  key_administrators  = local.key_administrators
  key_users           = local.key_users
  aws_region          = local.aws_region
  

}
