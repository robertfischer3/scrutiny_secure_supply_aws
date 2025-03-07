include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/eks"
}

inputs = {
  # EKS Cluster Configuration
  create_eks                      = true
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
      
      taints = []
      
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
  
  # Cluster Security Group additional rules
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
  
  # Node Security Group additional rules
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
  
  # AWS EFS CSI Driver for persistent volumes
  enable_efs_csi_driver = true
  
  # IRSA for Harbor components
  enable_irsa = true
  
  # Create IAM role for Harbor to access S3
  create_iam_role_harbor_s3 = true
  harbor_s3_bucket_arn      = dependency.s3.outputs.s3_bucket_arn
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