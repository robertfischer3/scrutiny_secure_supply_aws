# Environment-level variables for staging
locals {
  environment = "staging"
  
  # Network configuration
  vpc_cidr            = "10.0.0.0/16"
  availability_zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets      = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  # EKS configuration
  cluster_name        = "harbor-${local.environment}"
  kubernetes_version  = "1.28"
  node_instance_types = ["m5.large"]
  
  # Harbor configuration
  harbor_domain       = "harbor-${local.environment}.example.com"
  harbor_namespace    = "harbor"
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
}
