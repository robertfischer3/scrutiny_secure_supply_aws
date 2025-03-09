variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

# Storage settings
variable "storage_type" {
  description = "Storage type for Harbor registry (filesystem or s3)"
  type        = string
  default     = "filesystem"
  validation {
    condition     = contains(["filesystem", "s3"], var.storage_type)
    error_message = "Storage type must be either 'filesystem' or 's3'."
  }
}

# S3 settings
variable "s3_bucket_name" {
  description = "Name of the S3 bucket for Harbor storage"
  type        = string
  default     = ""
}

variable "s3_region" {
  description = "AWS region for S3 bucket"
  type        = string
  default     = "us-west-2"
}

variable "s3_access_key" {
  description = "AWS access key for S3 bucket. Use 'use_irsa' to enable IAM roles for service accounts"
  type        = string
  default     = "use_irsa"
}

variable "s3_secret_key" {
  description = "AWS secret key for S3 bucket. Use 'use_irsa' to enable IAM roles for service accounts"
  type        = string
  default     = "use_irsa"
  sensitive   = true
}

variable "s3_endpoint" {
  description = "Endpoint URL for S3 bucket"
  type        = string
  default     = ""
}

variable "s3_encrypt" {
  description = "Enable server-side encryption for S3 bucket"
  type        = bool
  default     = true
}

variable "s3_secure" {
  description = "Enable secure connection for S3 bucket"
  type        = bool
  default     = true
}

variable "s3_skipverify" {
  description = "Skip SSL verification for S3 bucket"
  type        = bool
  default     = false
}

variable "s3_v4auth" {
  description = "Enable v4 authentication for S3 bucket"
  type        = bool
  default     = true
}

variable "s3_chunksize" {
  description = "Chunk size for S3 multipart uploads (bytes)"
  type        = string
  default     = "10485760" # 10MB
}

variable "s3_rootdirectory" {
  description = "Root directory in S3 bucket for Harbor storage"
  type        = string
  default     = "/registry"
}

variable "s3_storageclass" {
  description = "Storage class for objects in S3 bucket"
  type        = string
  default     = "STANDARD"
}

variable "s3_multipartcopythreshold" {
  description = "Threshold for S3 multipart copy"
  type        = string
  default     = "33554432" # 32MB
}

variable "s3_multipartcopychunksize" {
  description = "Chunk size for S3 multipart copy"
  type        = string
  default     = "33554432" # 32MB
}

variable "s3_multipartcopymaxconcurrency" {
  description = "Maximum concurrency for S3 multipart copy"
  type        = number
  default     = 100
}

# TLS settings
variable "tls" {
  description = "TLS configuration for Harbor"
  type        = object({
    enabled        = bool
    cert_source    = string
    secret_name    = optional(string)
    ca_secret_name = optional(string)
  })
  default = {
    enabled     = true
    cert_source = "auto"
    secret_name = ""
    ca_secret_name = ""
  }
  validation {
    condition     = contains(["auto", "secret", "none"], var.tls.cert_source)
    error_message = "TLS cert source must be one of 'auto', 'secret', or 'none'."
  }
}

# ACM certificate ARN for ALB
variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for TLS termination at ALB"
  type        = string
  default     = ""
}

# Component enablement
variable "enable_notary" {
  description = "Enable Notary for content trust"
  type        = bool
  default     = false
}

variable "enable_trivy" {
  description = "Enable Trivy for vulnerability scanning"
  type        = bool
  default     = true
}

variable "enable_clair" {
  description = "Enable Clair for vulnerability scanning"
  type        = bool
  default     = false
}

variable "enable_chartmuseum" {
  description = "Enable ChartMuseum for Helm chart repository"
  type        = bool
  default     = true
}

# Resource settings
variable "resources" {
  description = "Resource requests and limits for Harbor components"
  type        = map(object({
    requests = object({
      memory = string
      cpu    = string
    })
    limits = object({
      memory = string
      cpu    = string
    })
  }))
  default = {
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
    database = {
      requests = {
        memory = "256Mi"
        cpu    = "100m"
      }
      limits = {
        memory = "512Mi"
        cpu    = "500m"
      }
    }
  }
}

# Persistence settings
variable "persistence" {
  description = "Persistence configuration for Harbor components"
  type = object({
    enabled      = bool
    storage_class = string
    registry = object({
      size = string
    })
    chartmuseum = optional(object({
      size = string
    }))
    jobservice = object({
      size = string
    })
    database = optional(object({
      size = string
    }))
    redis = optional(object({
      size = string
    }))
    trivy = optional(object({
      size = string
    }))
  })
  default = {
    enabled = true
    storage_class = "gp2"
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

# WAF integration
variable "waf_enabled" {
  description = "Enable WAF protection for Harbor"
  type        = bool
  default     = false
}

variable "waf_web_acl_arn" {
  description = "ARN of WAF Web ACL for Harbor"
  type        = string
  default     = ""
}

# Additional Harbor configurations
variable "additional_harbor_configs" {
  description = "Additional configuration parameters for Harbor"
  type        = any
  default     = {}
}

# Metrics configuration
variable "enable_metrics" {
  description = "Enable Prometheus metrics for Harbor"
  type        = bool
  default     = false
}

# Chart versions
variable "harbor_chart_version" {
  description = "Version of the Harbor Helm chart"
  type        = string
  default     = "1.12.2"
}

variable "postgresql_chart_version" {
  description = "Version of the PostgreSQL Helm chart"
  type        = string
  default     = "12.5.3"
}

variable "redis_chart_version" {
  description = "Version of the Redis Helm chart"
  type        = string
  default     = "17.11.3"
}

# EKS integration
variable "eks_cluster_name" {
  description = "Name of EKS cluster where Harbor will be deployed"
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "ARN of OIDC provider for EKS cluster"
  type        = string
  default     = ""
}

# Health checks
variable "create_health_check" {
  description = "Create a health check for Harbor"
  type        = bool
  default     = false
}

variable "health_check_target_group_arn" {
  description = "ARN of target group for Harbor health check"
  type        = string
  default     = ""
}

# CloudWatch integration
variable "create_cloudwatch_alarms" {
  description = "Create CloudWatch alarms for Harbor"
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "List of ARNs to notify when Harbor alarm transitions"
  type        = list(string)
  default     = []
}

variable "create_cloudwatch_dashboard" {
  description = "Create CloudWatch dashboard for Harbor"
  type        = bool
  default     = false
}

variable "load_balancer_arn" {
  description = "ARN of load balancer for Harbor"
  type        = string
  default     = ""
}

# AWS Region
variable "aws_region" {
  description = "AWS region where Harbor is deployed"
  type        = string
  default     = "us-west-2"
}

# Namespace settings
variable "namespace" {
  description = "Kubernetes namespace for Harbor deployment"
  type        = string
  default     = "harbor"
}

variable "create_namespace" {
  description = "Whether to create the Kubernetes namespace for Harbor"
  type        = bool
  default     = true
}

# Harbor domain settings
variable "harbor_domain" {
  description = "Domain name for Harbor registry"
  type        = string
}

# Database settings
variable "database_type" {
  description = "Database type for Harbor (internal or external)"
  type        = string
  default     = "external"
  validation {
    condition     = contains(["internal", "external"], var.database_type)
    error_message = "Database type must be either 'internal' or 'external'."
  }
}

variable "external_database" {
  description = "External database configuration"
  type        = object({
    host     = string
    port     = number
    username = string
    password = string
    name     = string
  })
  default     = null
}