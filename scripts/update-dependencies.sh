#!/bin/bash
# update-dependencies.sh - Update Terragrunt dependency configurations

set -e

# Configuration
ENVIRONMENT=${1:-dev}  # Default to dev if not specified
BASE_DIR="harbor-infrastructure/environments/$ENVIRONMENT"

# Helper functions
echo_green() {
  echo -e "\033[0;32m$1\033[0m"
}

echo_yellow() {
  echo -e "\033[0;33m$1\033[0m"
}

update_dependencies() {
  local module=$1
  local module_path="$BASE_DIR/$module"
  local terragrunt_file="$module_path/terragrunt.hcl"
  
  if [ ! -f "$terragrunt_file" ]; then
    echo_yellow "Warning: Terragrunt file not found at $terragrunt_file"
    return 1
  fi
  
  echo_green "Updating dependencies for $module..."
  
  # Different dependency configurations based on module
  case $module in
    "eks")
      # EKS depends on VPC and KMS
      cat > "$terragrunt_file" << EOF
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

# Explicitly state that this module cannot be created until VPC and KMS are ready
dependencies {
  paths = ["../vpc", "../kms", "../s3"]
}
EOF
      ;;
    "harbor")
      # Harbor depends on EKS, RDS, S3 and WAF
      cat > "$terragrunt_file" << EOF
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/harbor"
}

inputs = {
  # Basic settings
  namespace    = local.harbor_namespace
  create_namespace = true
  harbor_domain = local.harbor_domain

  # Dependencies
  eks_cluster_name    = dependency.eks.outputs.cluster_name
  eks_oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
  
  # Storage settings
  storage_type  = "s3"
  s3_bucket_name = dependency.s3.outputs.s3_bucket_id
  s3_region      = "us-west-2"
  s3_access_key  = "use_irsa" # Use IAM Roles for Service Accounts instead
  s3_secret_key  = "use_irsa" # Use IAM Roles for Service Accounts instead
  
  # Database settings
  database_type = "external"
  external_database = {
    host     = dependency.rds.outputs.db_instance_address
    port     = dependency.rds.outputs.db_instance_port
    name     = "registry"
    username = dependency.rds.outputs.db_instance_username
    password = dependency.rds.outputs.db_instance_password
  }
  
  # Security settings
  enable_notary = true
  enable_trivy  = true
  enable_clair  = false # Using Trivy instead
  
  # TLS settings
  tls = {
    enabled     = true
    cert_source = "auto" # Let Harbor generate a self-signed cert or use cert-manager
  }
  
  # Resource settings
  resources = {
    core = {
      requests = {
        memory = "256Mi"
        cpu    = "100m"
      }
      limits = {
        memory = "512Mi"
        cpu    = "500m"
      }
    }
    jobservice = {
      requests = {
        memory = "256Mi"
        cpu    = "100m"
      }
      limits = {
        memory = "512Mi"
        cpu    = "500m"
      }
    }
    registry = {
      requests = {
        memory = "256Mi"
        cpu    = "100m"
      }
      limits = {
        memory = "512Mi"
        cpu    = "500m"
      }
    }
    trivy = {
      requests = {
        memory = "512Mi"
        cpu    = "200m"
      }
      limits = {
        memory = "1Gi"
        cpu    = "1"
      }
    }
  }
  
  # WAF association
  waf_enabled = true
  waf_web_acl_arn = dependency.waf.outputs.web_acl_arn
  
  # Additional Harbor configurations for S2C2F compliance
  additional_harbor_configs = {
    # Enable audit logs
    log = {
      level = "info"
      audit = {
        enabled = true
      }
    }
    
    # Security scanner settings
    trivy = {
      githubToken = ""
      skipUpdate = false
      offline = false
    }
    
    # Redis settings for caching
    redis = {
      internal = {
        enabled = true
      }
    }
  }
  
  # Enable monitoring with Prometheus
  enable_metrics = true
  
  # Storage volumes configuration for persistent data
  persistence = {
    enabled = true
    storage_class = "efs-sc"
    registry = {
      size = "50Gi"
    }
    chartmuseum = {
      size = "5Gi"
    }
    jobservice = {
      size = "1Gi"
    }
    database = {
      size = "1Gi"
    }
    redis = {
      size = "1Gi"
    }
    trivy = {
      size = "5Gi"
    }
  }
}

dependency "eks" {
  config_path = "../eks"
  skip_outputs = false
}

dependency "rds" {
  config_path = "../rds"
  skip_outputs = false
}

dependency "s3" {
  config_path = "../s3"
  skip_outputs = false
}

dependency "waf" {
  config_path = "../waf"
  skip_outputs = false
}

# Explicitly state that this module cannot be created until dependencies are ready
dependencies {
  paths = ["../eks", "../rds", "../s3", "../waf"]
}
EOF
      ;;
    "rds")
      # RDS depends on VPC and KMS
      cat > "$terragrunt_file" << 'EOF'
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/rds"
}

inputs = {
  identifier           = "harbor-db-${local.environment}"
  engine               = "postgres"
  engine_version       = "15.3"
  instance_class       = local.environment == "prod" ? "db.m5.large" : "db.t3.medium"
  allocated_storage    = local.environment == "prod" ? 100 : 20
  max_allocated_storage = local.environment == "prod" ? 1000 : 100
  db_name              = "registry"
  username             = "harboradmin"
  password             = "PLACEHOLDER_TO_BE_CHANGED_BEFORE_APPLY"  # Use AWS Secrets Manager in actual deployment
  port                 = 5432
  
  vpc_id               = dependency.vpc.outputs.vpc_id
  subnet_ids           = dependency.vpc.outputs.private_subnets
  
  multi_az             = local.environment == "prod"
  deletion_protection  = local.environment == "prod"
  skip_final_snapshot  = local.environment != "prod"
  
  storage_encrypted    = true
  kms_key_id           = dependency.kms.outputs.key_arn
  
  backup_retention_period = local.environment == "prod" ? 30 : 7
  backup_window           = "03:00-05:00"
  maintenance_window      = "sun:05:00-sun:07:00"
  
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  
  # Security group rules
  security_group_rules = {
    ingress = {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = dependency.vpc.outputs.private_subnets_cidr_blocks
      description = "PostgreSQL from private subnets"
    }
  }
  
  # Parameter group settings
  parameters = [
    {
      name  = "log_statement"
      value = "all"
    },
    {
      name  = "log_min_duration_statement"
      value = "1000"  # Log queries taking more than 1 second
    }
  ]
}

dependency "vpc" {
  config_path = "../vpc"
  skip_outputs = false
}

dependency "kms" {
  config_path = "../kms"
  skip_outputs = false
}

# Explicitly state that this module cannot be created until dependencies are ready
dependencies {
  paths = ["../vpc", "../kms"]
}
EOF
      ;;
    "s3")
      # S3 depends on KMS
      cat > "$terragrunt_file" << 'EOF'
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/s3"
}

inputs = {
  bucket_name          = "harbor-artifacts-${local.environment}-${get_aws_account_id()}"
  force_destroy        = local.environment != "prod"
  versioning_enabled   = true
  sse_algorithm        = "aws:kms"
  kms_master_key_id    = dependency.kms.outputs.key_arn
  block_public_access  = true
  lifecycle_rule = {
    enabled = true
    expiration = {
      days = local.environment == "prod" ? 0 : 90  # 0 means never expire in prod
    }
    noncurrent_version_expiration = {
      days = local.environment == "prod" ? 365 : 30
    }
  }
  cors_rule = {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["https://${local.harbor_domain}"]
    max_age_seconds = 3000
  }
}

dependency "kms" {
  config_path = "../kms"
  skip_outputs = false
}

# Explicitly state that this module cannot be created until dependencies are ready
dependencies {
  paths = ["../kms"]
}
EOF
      ;;
    "efs")
      # EFS depends on VPC and KMS
      cat > "$terragrunt_file" << 'EOF'
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
  skip_outputs = false
}

dependency "kms" {
  config_path = "../kms"
  skip_outputs = false
}

# Explicitly state that this module cannot be created until dependencies are ready
dependencies {
  paths = ["../vpc", "../kms"]
}
EOF
      ;;
    "cloudflare")
      # Cloudflare depends on Harbor
      cat > "$terragrunt_file" << EOF
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/cloudflare"
}

dependency "harbor" {
  config_path = "../harbor"
  skip_outputs = false
}

inputs = {
  domain_name    = "example.com"
  subdomain      = "harbor-${local.environment}"
  origin_address = dependency.harbor.outputs.load_balancer_hostname
  
  # Don't create a zone by default, use an existing one
  create_zone    = false
  zone_id        = "your-cloudflare-zone-id"
  
  # Zero Trust settings
  enable_zero_trust = local.environment == "prod"
  allowed_groups    = ["harbor-admins", "developers"]
  
  # Rate limiting
  rate_limit_threshold = local.environment == "prod" ? 1000 : 2000
  rate_limit_period    = 60
}

# Explicitly state that this module cannot be created until dependencies are ready
dependencies {
  paths = ["../harbor"]
}
EOF
      ;;
    "vpc")
      # VPC has no dependencies but we'll still update for consistency
      cat > "$terragrunt_file" << 'EOF'
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
EOF
      ;;
    "kms")
      # KMS has no dependencies
cat > "$terragrunt_file" << 'EOF'
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/kms"
}

inputs = {
  alias_name                   = "alias/harbor-keys-${local.environment}"
  description                  = "KMS key for Harbor encryption in ${local.environment}"
  deletion_window_in_days      = 30
  enable_key_rotation          = true
  enable_default_policy        = true
  key_administrators           = ["arn:aws:iam::${get_aws_account_id()}:role/Admin"]
  key_users                    = ["arn:aws:iam::${get_aws_account_id()}:role/HarborKMSUser"]
  attach_to_eks_role           = false  # Will be updated after EKS is created
}
EOF
      ;;
    "waf")
      # WAF has no direct infrastructure dependencies
      cat > "$terragrunt_file" << 'EOF'
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/waf"
}

inputs = {
  name               = "harbor-waf-${local.environment}"
  scope              = "REGIONAL"
  
  # Default actions
  default_action     = "allow"
  visibility_config  = {
    cloudwatch_metrics_enabled = true
    metric_name                = "harbor-waf-${local.environment}"
    sampled_requests_enabled   = true
  }
  
  # WAF rules
  rules = [
    {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 10
      override_action = "none"
      
      statement = {
        managed_rule_group_statement = {
          name        = "AWSManagedRulesCommonRuleSet"
          vendor_name = "AWS"
        }
      }
      
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesCommonRuleSet"
        sampled_requests_enabled   = true
      }
    },
    {
      name     = "AWSManagedRulesKnownBadInputsRuleSet"
      priority = 20
      override_action = "none"
      
      statement = {
        managed_rule_group_statement = {
          name        = "AWSManagedRulesKnownBadInputsRuleSet"
          vendor_name = "AWS"
        }
      }
      
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
        sampled_requests_enabled   = true
      }
    },
    {
      name     = "AWSManagedRulesSQLiRuleSet"
      priority = 30
      override_action = "none"
      
      statement = {
        managed_rule_group_statement = {
          name        = "AWSManagedRulesSQLiRuleSet"
          vendor_name = "AWS"
        }
      }
      
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesSQLiRuleSet"
        sampled_requests_enabled   = true
      }
    },
    {
      name     = "RateLimit"
      priority = 40
      action   = "block"
      
      statement = {
        rate_based_statement = {
          limit              = 1000
          aggregate_key_type = "IP"
        }
      }
      
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "RateLimit"
        sampled_requests_enabled   = true
      }
    }
  ]
}
EOF
      ;;
    *)
      echo_yellow "No specific dependency configuration needed for $module, skipping..."
      ;;
  esac
}

# Main function to update all module dependencies
update_all_dependencies() {
  echo_green "Updating dependencies for all modules in $ENVIRONMENT environment..."
  
  # Define all modules
  MODULES=("kms" "vpc" "s3" "efs" "rds" "waf" "eks" "harbor" "cloudflare")
  
  for module in "${MODULES[@]}"; do
    update_dependencies $module
  done
  
  echo_green "Dependencies updated successfully for all modules!"
}

# Add local-exec module for pre-destroy cleanups
create_cleanup_module() {
  echo_green "Creating cleanup module for EKS resources..."
  
  local cleanup_dir="$BASE_DIR/cleanup"
  mkdir -p $cleanup_dir
  
  cat > "$cleanup_dir/terragrunt.hcl" << EOF
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/cleanup"
}

inputs = {
  eks_cluster_name = dependency.eks.outputs.cluster_name
}

dependency "eks" {
  config_path = "../eks"
}

dependencies {
  paths = ["../eks"]
}
EOF

  # Create necessary module files
  mkdir -p "harbor-infrastructure/modules/cleanup"
  
  cat > "harbor-infrastructure/modules/cleanup/main.tf" << EOF
resource "null_resource" "cleanup_eks_resources" {
  triggers = {
    cluster_name = var.eks_cluster_name
  }

  # Pre-cleanup step - removes resources that might block deletion
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Starting pre-destroy cleanup for EKS cluster \${self.triggers.cluster_name}..."
      
      # Update kubeconfig
      aws eks update-kubeconfig --name \${self.triggers.cluster_name} --region us-west-2

      # Delete all Harbor resources
      kubectl delete namespace harbor --ignore-not-found=true
      
      # Remove load balancers
      kubectl delete svc --all -A --ignore-not-found=true
      
      # Remove persistent volumes and claims
      kubectl delete pvc --all -A --ignore-not-found=true
      kubectl delete pv --all --ignore-not-found=true
      
      # Wait for resources to be cleaned up
      echo "Waiting for resources to be cleaned up..."
      sleep 60

      echo "Pre-destroy cleanup completed"
    EOT
  }
}
EOF

  cat > "harbor-infrastructure/modules/cleanup/variables.tf" << EOF
variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}
EOF

  cat > "harbor-infrastructure/modules/cleanup/outputs.tf" << EOF
output "cleanup_completed" {
  description = "Indicates if cleanup has been completed"
  value       = "true"
}
EOF

  echo_green "Cleanup module created successfully!"
}

# Check command line arguments
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
  echo "Usage: $0 [environment] [--create-cleanup]"
  echo ""
  echo "Options:"
  echo "  environment     Target environment (dev, staging, prod, defaults to dev)"
  echo "  --create-cleanup  Create a cleanup module for pre-destroy operations"
  exit 0
fi

# Process args
if [ "$2" == "--create-cleanup" ] || [ "$1" == "--create-cleanup" ]; then
  create_cleanup_module
fi

# Run the main function
update_all_dependencies