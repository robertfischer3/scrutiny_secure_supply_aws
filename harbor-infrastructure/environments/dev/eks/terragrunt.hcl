include {
  path = find_in_parent_folders()
}

include "env" {
  path = find_in_parent_folders("dev_env.hcl")
  expose = true
  merge_strategy = "no_merge"
}

terraform {
  source = "../../../modules/eks"
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "kms" {
  config_path = "../kms"
}

dependency "s3" {
  config_path = "../s3"
}

dependency "efs" {  # Add EFS dependency for proper ordering
  config_path = "../efs"
  skip_outputs = true  # Skip outputs to avoid circular dependency
}

inputs = {
  # EKS Cluster Configuration
  name                            = local.cluster_name
  cluster_version                 = local.kubernetes_version
  vpc_id                          = dependency.vpc.outputs.vpc_id
  subnet_ids                      = dependency.vpc.outputs.private_subnets
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  
  # Encryption Configuration
  cluster_encryption_config = [{
    provider_key_arn = dependency.kms.outputs.key_arn
    resources        = ["secrets"]
  }]
  
  # Node Group Configuration
  eks_managed_node_groups = {
    harbor = {
      instance_types = local.node_instance_types
      min_size       = 2
      max_size       = local.environment == "prod" ? 10 : 5
      desired_size   = local.environment == "prod" ? 3 : 2
      
      labels = {
        Environment = local.environment
        Application = "Harbor"
      }
      
      # Updated taints configuration
      taints = [{
        key    = "dedicated"
        value  = "harbor"
        effect = "NO_SCHEDULE"
      }]
      
      update_config = {
        max_unavailable_percentage = 50
      }
      
      # Disk encryption
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            encrypted             = true
            kms_key_id            = dependency.kms.outputs.key_arn
            delete_on_termination = true
          }
        }
      }
    }
  }
  
  # Amazon EBS CSI Driver for persistent volumes
  enable_amazon_eks_aws_ebs_csi_driver = true
  
  # AWS Load Balancer Controller for ingress
  enable_aws_load_balancer_controller = true
  
  # EFS CSI Driver configuration
  enable_efs_csi_driver = true
  efs_file_system_id    = dependency.efs.outputs.id  # Reference EFS output
  
  # Enable IRSA for Harbor components
  enable_irsa = true
  
  # Create IAM role for Harbor to access S3
  create_iam_role_harbor_s3 = true
  harbor_s3_bucket_arn      = dependency.s3.outputs.s3_bucket_arn
  
  # Additional security configuration
  cluster_security_group_cidr_blocks = [local.vpc_cidr]
}

# Dependencies
dependencies {
  paths = ["../vpc", "../kms", "../s3", "../efs"]
}