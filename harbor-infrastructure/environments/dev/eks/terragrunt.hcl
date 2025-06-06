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

dependency "efs" {
  config_path = "../efs"
  mock_outputs = {
    id = "fs-12345abcdef"
  }
  skip_outputs = true  # Skip outputs in validation to avoid circular dependency
}

inputs = {
  # Basic EKS Cluster Configuration
  name                            = local.cluster_name
  environment                     = local.environment
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
      
      # Taints configuration
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
  
  # AWS Region
  aws_region = local.aws_region
  
  # Enhanced security configuration
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = local.environment == "prod" ? 90 : 30
  
  # Security group rules
  cluster_security_group_cidr_blocks = [local.vpc_cidr]
  cluster_security_group_additional_rules = {
    egress_all = {
      description      = "Cluster all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  }
  
  node_security_group_additional_rules = {
    ingress_self_all = {
      description      = "Node to node all ports/protocols"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "ingress"
      self             = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  }
  
  # IAM configuration
  enable_irsa = true
  manage_aws_auth_configmap = true
  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::${local.account_id}:role/Admin"
      username = "admin"
      groups   = ["system:masters"]
    }
  ]
  
  # Additional Harbor configurations
  create_iam_role_harbor_s3 = true
  harbor_s3_bucket_arn      = dependency.s3.outputs.s3_bucket_arn
  harbor_namespace          = local.harbor_namespace
  
  # Add-on configurations
  enable_aws_load_balancer_controller = true
  
  enable_amazon_eks_aws_ebs_csi_driver = true
  aws_ebs_csi_driver_version = "v1.26.0-eksbuild.1"
  
  enable_efs_csi_driver = true
  efs_csi_driver_version = "v1.5.8-eksbuild.1"
  efs_file_system_id    = dependency.efs.outputs.id
  
  enable_vpc_cni_addon = true
  vpc_cni_addon_version = "v1.14.0-eksbuild.1"
  
  enable_coredns_addon = true
  coredns_addon_version = "v1.10.1-eksbuild.1"
  
  enable_kube_proxy_addon = true
  kube_proxy_addon_version = "v1.28.1-eksbuild.1"
  
  enable_metrics_server = true
  metrics_server_version = "3.10.0"
  
  enable_cluster_autoscaler = true
  cluster_autoscaler_version = "9.29.0"
  
  enable_adot_addon = local.environment == "prod" ? true : false
  adot_addon_version = "v0.90.0-eksbuild.1"
  
  # Advanced feature configurations
  enable_pod_identity = false  # Set to true when you're ready to migrate from IRSA
  
  # Observability configurations
  enable_amazon_prometheus = local.environment == "prod" ? true : false
  enable_amazon_grafana = local.environment == "prod" ? true : false
  
  # Tags
  tags = {
    Environment = local.environment
    Project     = "Harbor-S2C2F"
    ManagedBy   = "Terragrunt"
    Component   = "EKS"
  }
}

# Dependencies
dependencies {
  paths = ["../vpc", "../kms", "../s3", "../efs"]
}