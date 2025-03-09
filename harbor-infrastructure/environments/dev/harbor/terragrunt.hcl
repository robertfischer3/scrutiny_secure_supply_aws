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
