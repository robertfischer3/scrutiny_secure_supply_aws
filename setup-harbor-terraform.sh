#!/bin/bash
# Script to generate Harbor S2C2F Terraform/Terragrunt directory structure

set -e

# Root directory for the project
PROJECT_DIR="harbor-infrastructure"

# Environments to create
ENVIRONMENTS=("dev" "staging" "prod")

# Modules to create
MODULES=("vpc" "eks" "rds" "s3" "efs" "kms" "waf" "harbor")

# Create the base directory structure
echo "Creating project directory structure..."
mkdir -p "$PROJECT_DIR/modules"
mkdir -p "$PROJECT_DIR/environments"

# Create module directories and base files
echo "Creating module directories..."
for module in "${MODULES[@]}"; do
  mkdir -p "$PROJECT_DIR/modules/$module"
  touch "$PROJECT_DIR/modules/$module/main.tf"
  touch "$PROJECT_DIR/modules/$module/variables.tf"
  touch "$PROJECT_DIR/modules/$module/outputs.tf"
  
  # Add template content to main.tf
  cat > "$PROJECT_DIR/modules/$module/main.tf" << EOF
# $module module for Harbor S2C2F implementation

# Main resources will be defined here
EOF

  # Add template content to variables.tf
  cat > "$PROJECT_DIR/modules/$module/variables.tf" << EOF
# Variables for $module module

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

# Additional variables will be defined here
EOF

  # Add template content to outputs.tf
  cat > "$PROJECT_DIR/modules/$module/outputs.tf" << EOF
# Outputs for $module module

# Module outputs will be defined here
EOF
done

# Create environment directories and terragrunt files
echo "Creating environment directories..."
for env in "${ENVIRONMENTS[@]}"; do
  mkdir -p "$PROJECT_DIR/environments/$env"
  
  # Create environment-level terragrunt.hcl
  cat > "$PROJECT_DIR/environments/$env/terragrunt.hcl" << EOF
# Environment-level variables for $env
locals {
  environment = "$env"
  
  # Network configuration
  vpc_cidr            = "10.0.0.0/16"
  availability_zones  = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets      = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  # EKS configuration
  cluster_name        = "harbor-\${local.environment}"
  kubernetes_version  = "1.28"
  node_instance_types = ["m5.large"]
  
  # Harbor configuration
  harbor_domain       = "harbor-\${local.environment}.example.com"
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
EOF

  # Create module directories for each environment
  for module in "${MODULES[@]}"; do
    mkdir -p "$PROJECT_DIR/environments/$env/$module"
    
    # Create terragrunt.hcl for each module
    cat > "$PROJECT_DIR/environments/$env/$module/terragrunt.hcl" << EOF
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/$module"
}

# Module-specific inputs will be defined here

# Dependencies will be defined here if needed
EOF
  done
done

# Create root terragrunt.hcl with careful handling of nested EOFs
cat > "$PROJECT_DIR/terragrunt.hcl" << 'EOT'
remote_state {
  backend = "s3"
  config = {
    bucket         = "harbor-terraform-state-${get_aws_account_id()}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "harbor-terraform-locks"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "us-east-1"
      
      default_tags {
        tags = {
          Environment = "${local.env}"
          Project     = "Harbor-S2C2F"
          ManagedBy   = "Terraform"
        }
      }
    }

    provider "kubernetes" {
      host                   = data.aws_eks_cluster.cluster.endpoint
      cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
      token                  = data.aws_eks_cluster_auth.cluster.token
    }

    provider "helm" {
      kubernetes {
        host                   = data.aws_eks_cluster.cluster.endpoint
        cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
        token                  = data.aws_eks_cluster_auth.cluster.token
      }
    }
  EOF
}

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = "~> 5.0"
        }
        kubernetes = {
          source  = "hashicorp/kubernetes"
          version = "~> 2.20"
        }
        helm = {
          source  = "hashicorp/helm" 
          version = "~> 2.9"
        }
      }
      required_version = ">= 1.3.0"
    }
  EOF
}

locals {
  env = regex(".*/([^/]+)/.+$", get_terragrunt_dir())[0]
}
EOT

# Additional file for Cloudflare integration
mkdir -p "$PROJECT_DIR/modules/cloudflare"
touch "$PROJECT_DIR/modules/cloudflare/main.tf"
touch "$PROJECT_DIR/modules/cloudflare/variables.tf"
touch "$PROJECT_DIR/modules/cloudflare/outputs.tf"

cat > "$PROJECT_DIR/modules/cloudflare/main.tf" << EOF
# Cloudflare module for Harbor S2C2F implementation

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# Cloudflare zone for the domain
resource "cloudflare_zone" "harbor_zone" {
  count = var.create_zone ? 1 : 0
  zone  = var.domain_name
}

# DNS record for Harbor
resource "cloudflare_record" "harbor" {
  zone_id = var.create_zone ? cloudflare_zone.harbor_zone[0].id : var.zone_id
  name    = var.subdomain
  value   = var.origin_address
  type    = "CNAME"
  proxied = true
}

# WAF configuration
resource "cloudflare_ruleset" "harbor_waf" {
  zone_id     = var.create_zone ? cloudflare_zone.harbor_zone[0].id : var.zone_id
  name        = "Harbor Registry Protection"
  description = "WAF rules to protect Harbor registry"
  kind        = "zone"
  phase       = "http_request_firewall_managed"

  rules {
    action = "execute"
    action_parameters {
      id = "efb7b8c949ac4650a09736fc376e9aee"
    }
    expression  = "true"
    description = "OWASP Core Ruleset"
    enabled     = true
  }
}

# Zero Trust Access policy (if enabled)
resource "cloudflare_access_application" "harbor_app" {
  count       = var.enable_zero_trust ? 1 : 0
  zone_id     = var.create_zone ? cloudflare_zone.harbor_zone[0].id : var.zone_id
  name        = "Harbor Registry"
  domain      = "\${var.subdomain}.\${var.domain_name}"
  session_duration = "24h"
}

resource "cloudflare_access_policy" "harbor_policy" {
  count             = var.enable_zero_trust ? 1 : 0
  application_id    = cloudflare_access_application.harbor_app[0].id
  zone_id           = var.create_zone ? cloudflare_zone.harbor_zone[0].id : var.zone_id
  name              = "Harbor Access"
  precedence        = 1
  decision          = "allow"
  
  include {
    group = var.allowed_groups
  }
}

# Rate limiting rule
resource "cloudflare_rate_limit" "harbor_rate_limit" {
  zone_id           = var.create_zone ? cloudflare_zone.harbor_zone[0].id : var.zone_id
  threshold         = var.rate_limit_threshold
  period            = var.rate_limit_period
  match {
    request {
      url_pattern   = "*"
      schemes       = ["HTTP", "HTTPS"]
      methods       = ["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD"]
    }
  }
  action {
    mode           = "simulate"
    timeout        = 60
    response {
      content_type = "text/plain"
      body         = "You have exceeded the rate limit. Please try again later."
    }
  }
  disabled          = false
  description       = "Rate limiting for Harbor registry"
}

# Page rules
resource "cloudflare_page_rule" "force_ssl" {
  zone_id  = var.create_zone ? cloudflare_zone.harbor_zone[0].id : var.zone_id
  target   = "*.\${var.domain_name}/*"
  priority = 1

  actions {
    always_use_https = true
  }
}
EOF

cat > "$PROJECT_DIR/modules/cloudflare/variables.tf" << EOF
# Variables for Cloudflare module

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "domain_name" {
  description = "The domain name to use for Harbor"
  type        = string
}

variable "subdomain" {
  description = "The subdomain for Harbor"
  type        = string
  default     = "harbor"
}

variable "origin_address" {
  description = "The origin address (ALB DNS name) for Harbor"
  type        = string
}

variable "create_zone" {
  description = "Whether to create a new Cloudflare zone"
  type        = bool
  default     = false
}

variable "zone_id" {
  description = "Cloudflare zone ID if not creating a new zone"
  type        = string
  default     = ""
}

variable "enable_zero_trust" {
  description = "Whether to enable Cloudflare Zero Trust"
  type        = bool
  default     = false
}

variable "allowed_groups" {
  description = "List of groups allowed to access Harbor through Zero Trust"
  type        = list(string)
  default     = []
}

variable "rate_limit_threshold" {
  description = "Number of requests before rate limiting kicks in"
  type        = number
  default     = 1000
}

variable "rate_limit_period" {
  description = "The time period in seconds for rate limiting"
  type        = number
  default     = 60
}
EOF

cat > "$PROJECT_DIR/modules/cloudflare/outputs.tf" << EOF
# Outputs for Cloudflare module

output "cloudflare_zone_id" {
  description = "The Cloudflare zone ID"
  value       = var.create_zone ? cloudflare_zone.harbor_zone[0].id : var.zone_id
}

output "harbor_dns_record" {
  description = "The full Harbor DNS record"
  value       = "\${var.subdomain}.\${var.domain_name}"
}
EOF

for env in "${ENVIRONMENTS[@]}"; do
  mkdir -p "$PROJECT_DIR/environments/$env/cloudflare"
  
  # Create terragrunt.hcl for cloudflare module
  cat > "$PROJECT_DIR/environments/$env/cloudflare/terragrunt.hcl" << 'EOF'
include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/cloudflare"
}

dependency "harbor" {
  config_path = "../harbor"
}

inputs = {
  domain_name    = "example.com"
  subdomain      = "harbor-ENV"
  origin_address = dependency.harbor.outputs.load_balancer_hostname
  
  # Don't create a zone by default, use an existing one
  create_zone    = false
  zone_id        = "your-cloudflare-zone-id"
  
  # Zero Trust settings
  enable_zero_trust = ZERO_TRUST_VALUE
  allowed_groups    = ["harbor-admins", "developers"]
  
  # Rate limiting
  rate_limit_threshold = RATE_LIMIT_VALUE
  rate_limit_period    = 60
}
EOF

  # Now replace the placeholders with actual values
  sed -i "s/ENV/$env/g" "$PROJECT_DIR/environments/$env/cloudflare/terragrunt.hcl"
  
  if [ "$env" == "prod" ]; then
    sed -i "s/ZERO_TRUST_VALUE/true/g" "$PROJECT_DIR/environments/$env/cloudflare/terragrunt.hcl"
    sed -i "s/RATE_LIMIT_VALUE/1000/g" "$PROJECT_DIR/environments/$env/cloudflare/terragrunt.hcl"
  else
    sed -i "s/ZERO_TRUST_VALUE/false/g" "$PROJECT_DIR/environments/$env/cloudflare/terragrunt.hcl"
    sed -i "s/RATE_LIMIT_VALUE/2000/g" "$PROJECT_DIR/environments/$env/cloudflare/terragrunt.hcl"
  fi
done