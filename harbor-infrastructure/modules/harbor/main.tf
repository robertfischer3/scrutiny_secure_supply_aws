resource "kubernetes_namespace" "harbor" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      name        = var.namespace
      environment = var.environment
    }
  }
}

# Create Kubernetes secret for database credentials
resource "kubernetes_secret" "harbor_database" {
  metadata {
    name      = "harbor-database-credentials"
    namespace = var.create_namespace ? kubernetes_namespace.harbor[0].metadata[0].name : var.namespace
  }

  data = {
    username = var.database_type == "external" ? var.external_database.username : "postgres"
    password = var.database_type == "external" ? var.external_database.password : random_password.postgres_password[0].result
    host     = var.database_type == "external" ? var.external_database.host : "${helm_release.postgresql[0].name}-postgresql.${var.namespace}.svc.cluster.local"
    port     = var.database_type == "external" ? tostring(var.external_database.port) : "5432"
    database = var.database_type == "external" ? var.external_database.name : "registry"
  }

  type = "Opaque"

  depends_on = [
    kubernetes_namespace.harbor
  ]
}

# Create Kubernetes secret for S3 credentials when not using IRSA
resource "kubernetes_secret" "harbor_s3" {
  count = var.storage_type == "s3" && var.s3_access_key != "use_irsa" ? 1 : 0

  metadata {
    name      = "harbor-s3-credentials"
    namespace = var.create_namespace ? kubernetes_namespace.harbor[0].metadata[0].name : var.namespace
  }

  data = {
    accesskey = var.s3_access_key
    secretkey = var.s3_secret_key
  }

  type = "Opaque"

  depends_on = [
    kubernetes_namespace.harbor
  ]
}

# Create random password for PostgreSQL if using internal database
resource "random_password" "postgres_password" {
  count   = var.database_type == "internal" ? 1 : 0
  length  = 16
  special = false
}

# Deploy PostgreSQL if using internal database
resource "helm_release" "postgresql" {
  count      = var.database_type == "internal" ? 1 : 0
  name       = "harbor-postgresql"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = var.postgresql_chart_version
  namespace  = var.create_namespace ? kubernetes_namespace.harbor[0].metadata[0].name : var.namespace

  values = [
    yamlencode({
      auth = {
        username = "postgres"
        password = random_password.postgres_password[0].result
        database = "registry"
      }
      primary = {
        persistence = {
          enabled      = true
          storageClass = var.persistence.storage_class
          size         = var.persistence.database.size
        }
        resources = var.resources.database
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.harbor
  ]
}

# Deploy Redis if using internal Redis
resource "helm_release" "redis" {
  count      = lookup(lookup(lookup(var.additional_harbor_configs, "redis", {}), "internal", {}), "enabled", false) ? 1 : 0
  name       = "harbor-redis"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  version    = var.redis_chart_version
  namespace  = var.create_namespace ? kubernetes_namespace.harbor[0].metadata[0].name : var.namespace

  values = [
    yamlencode({
      auth = {
        enabled = true
        password = random_password.redis_password[0].result
      }
      master = {
        persistence = {
          enabled      = true
          storageClass = var.persistence.storage_class
          size         = lookup(var.persistence, "redis", { size = "1Gi" }).size
        }
        resources = lookup(var.resources, "redis", {
          requests = {
            memory = "256Mi"
            cpu    = "100m"
          }
          limits = {
            memory = "512Mi"
            cpu    = "250m"
          }
        })
      }
      replica = {
        replicaCount = 0
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.harbor
  ]
}

# Create random password for Redis if using internal Redis
resource "random_password" "redis_password" {
  count   = lookup(lookup(lookup(var.additional_harbor_configs, "redis", {}), "internal", {}), "enabled", false) ? 1 : 0
  length  = 16
  special = false
}

# Deploy Harbor using Helm chart
resource "helm_release" "harbor" {
  name       = "harbor"
  repository = "https://helm.goharbor.io"
  chart      = "harbor"
  version    = var.harbor_chart_version
  namespace  = var.create_namespace ? kubernetes_namespace.harbor[0].metadata[0].name : var.namespace
  timeout    = 1200 # 20 minutes

  values = [
    templatefile("${path.module}/templates/values.yaml.tpl", {
      harbor_domain = var.harbor_domain
      
      # Database settings
      database_type = var.database_type
      database = {
        type     = "external"
        host     = var.database_type == "external" ? var.external_database.host : "${helm_release.postgresql[0].name}-postgresql.${var.namespace}.svc.cluster.local"
        port     = var.database_type == "external" ? var.external_database.port : 5432
        username = var.database_type == "external" ? var.external_database.username : "postgres"
        password = var.database_type == "external" ? var.external_database.password : random_password.postgres_password[0].result
        database = var.database_type == "external" ? var.external_database.name : "registry"
      }
      
      # Storage settings for registry
      storage_type = var.storage_type
      s3 = var.storage_type == "s3" ? {
        region            = var.s3_region
        bucket            = var.s3_bucket_name
        accesskey         = var.s3_access_key
        secretkey         = var.s3_secret_key
        regionendpoint    = var.s3_endpoint
        encrypt           = var.s3_encrypt
        secure            = var.s3_secure
        skipverify        = var.s3_skipverify
        v4auth            = var.s3_v4auth
        chunksize         = var.s3_chunksize
        rootdirectory     = var.s3_rootdirectory
        storageclass      = var.s3_storageclass
        multipartcopythreshold = var.s3_multipartcopythreshold
        multipartcopychunksize = var.s3_multipartcopychunksize
        multipartcopymaxconcurrency = var.s3_multipartcopymaxconcurrency
        use_iam_role      = var.s3_access_key == "use_irsa"
      } : null
      
      # TLS settings
      tls = {
        enabled     = var.tls.enabled
        cert_source = var.tls.cert_source
        secret_name = var.tls.secret_name
        ca_secret_name = var.tls.ca_secret_name
        auto_cert = {
          enabled     = var.tls.cert_source == "auto"
          common_name = var.harbor_domain
        }
      }
      
      # Component enablement
      enable_notary = var.enable_notary
      enable_trivy  = var.enable_trivy
      enable_clair  = var.enable_clair
      enable_chartmuseum = var.enable_chartmuseum
      
      # Resource settings
      resources = var.resources
      
      # Persistence configuration
      persistence = var.persistence
      
      # Ingress configuration
      expose = {
        type                 = "ingress"
        ingress = {
          annotations = {
            "kubernetes.io/ingress.class" = "alb"
            "alb.ingress.kubernetes.io/scheme" = "internet-facing"
            "alb.ingress.kubernetes.io/target-type" = "ip"
            "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
            "alb.ingress.kubernetes.io/actions.ssl-redirect" = "{\"Type\": \"redirect\", \"RedirectConfig\": {\"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\"}}"
            "alb.ingress.kubernetes.io/certificate-arn" = var.acm_certificate_arn
            "alb.ingress.kubernetes.io/success-codes" = "200,404"
            "alb.ingress.kubernetes.io/healthcheck-path" = "/api/v2.0/ping"
            "alb.ingress.kubernetes.io/group.name" = "harbor"
            "alb.ingress.kubernetes.io/ssl-policy" = "ELBSecurityPolicy-TLS-1-2-2017-01"
            "alb.ingress.kubernetes.io/wafv2-acl-arn" = var.waf_enabled ? var.waf_web_acl_arn : ""
          }
          harbor_host = var.harbor_domain
        }
      }
      
      # Additional Harbor configurations
      additional_harbor_configs = var.additional_harbor_configs
      
      # Redis configuration if internal Redis is enabled
      redis = {
        type = lookup(lookup(var.additional_harbor_configs, "redis", {}), "internal", { enabled = false }).enabled ? "internal" : "external"
        internal = lookup(lookup(var.additional_harbor_configs, "redis", {}), "internal", { enabled = false }).enabled ? {
          host = "harbor-redis-master"
          port = 6379
          password = lookup(lookup(var.additional_harbor_configs, "redis", {}), "internal", { enabled = false }).enabled ? random_password.redis_password[0].result : ""
          database = 0
        } : null
        external = lookup(lookup(var.additional_harbor_configs, "redis", {}), "external", null)
      }
      
      # Metrics/Prometheus configuration
      metrics = {
        enabled = var.enable_metrics
        core = {
          path     = "/metrics"
          port     = 8001
        }
      }
    })
  ]

  # Wait for database to be ready
  depends_on = [
    kubernetes_namespace.harbor,
    kubernetes_secret.harbor_database,
    kubernetes_secret.harbor_s3,
    helm_release.postgresql,
    helm_release.redis
  ]
}

# Create IAM role for Harbor to access S3 using IRSA if enabled
data "aws_iam_policy_document" "harbor_s3_access" {
  count = var.storage_type == "s3" && var.s3_access_key == "use_irsa" ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:ListBucketVersions",
      "s3:ListBucketMultipartUploads",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
  }
}

resource "aws_iam_policy" "harbor_s3_access" {
  count       = var.storage_type == "s3" && var.s3_access_key == "use_irsa" ? 1 : 0
  name        = "harbor-s3-access-${var.environment}"
  description = "IAM policy allowing Harbor to access S3 bucket"
  policy      = data.aws_iam_policy_document.harbor_s3_access[0].json
}

module "iam_assumable_role_with_oidc" {
  count       = var.storage_type == "s3" && var.s3_access_key == "use_irsa" ? 1 : 0
  source      = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version     = "~> 5.0"

  create_role                   = true
  role_name                     = "harbor-s3-${var.environment}"
  provider_url                  = replace(var.eks_oidc_provider_arn, "/^arn:aws:iam::[0-9]{12}:oidc-provider\\//", "")
  role_policy_arns              = [aws_iam_policy.harbor_s3_access[0].arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${var.namespace}:harbor-registry"]
}

# Annotate the Harbor registry service account with IAM role for IRSA
resource "kubernetes_service_account" "harbor_registry" {
  count = var.storage_type == "s3" && var.s3_access_key == "use_irsa" ? 1 : 0

  metadata {
    name      = "harbor-registry"
    namespace = var.create_namespace ? kubernetes_namespace.harbor[0].metadata[0].name : var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam_assumable_role_with_oidc[0].iam_role_arn
    }
  }

  depends_on = [
    kubernetes_namespace.harbor
  ]
}

# Create ALB Target Group health check to ensure Harbor is healthy
resource "aws_lb_target_group_attachment" "harbor_health_check" {
  count = var.create_health_check && var.health_check_target_group_arn != "" ? 1 : 0

  target_group_arn = var.health_check_target_group_arn
  target_id        = data.aws_instances.harbor_nodes[0].ids[0]
  port             = 80
}

data "aws_instances" "harbor_nodes" {
  count = var.create_health_check && var.health_check_target_group_arn != "" ? 1 : 0

  instance_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  depends_on = [
    helm_release.harbor
  ]
}

# Get the load balancer DNS name for output
data "kubernetes_ingress_v1" "harbor" {
  metadata {
    name      = "harbor-ingress"
    namespace = var.create_namespace ? kubernetes_namespace.harbor[0].metadata[0].name : var.namespace
  }

  depends_on = [
    helm_release.harbor
  ]
}

# CloudWatch metric alarms for Harbor health
resource "aws_cloudwatch_metric_alarm" "harbor_health" {
  count               = var.create_cloudwatch_alarms ? 1 : 0
  alarm_name          = "harbor-health-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "This metric monitors the health of Harbor instances"
  
  dimensions = {
    TargetGroup  = var.health_check_target_group_arn != "" ? var.health_check_target_group_arn : "harbor-target-group"
    LoadBalancer = var.load_balancer_arn != "" ? var.load_balancer_arn : "harbor-lb"
  }
  
  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions
}

# Create CloudWatch Dashboard for Harbor
resource "aws_cloudwatch_dashboard" "harbor" {
  count          = var.create_cloudwatch_dashboard ? 1 : 0
  dashboard_name = "harbor-dashboard-${var.environment}"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.load_balancer_arn != "" ? var.load_balancer_arn : "harbor-lb"]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Harbor Request Count"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", var.load_balancer_arn != "" ? var.load_balancer_arn : "harbor-lb"],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.load_balancer_arn != "" ? var.load_balancer_arn : "harbor-lb"]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Harbor Error Codes"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", var.load_balancer_arn != "" ? var.load_balancer_arn : "harbor-lb"]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "Harbor Healthy Hosts"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.load_balancer_arn != "" ? var.load_balancer_arn : "harbor-lb"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Harbor Response Time"
        }
      }
    ]
  })
}