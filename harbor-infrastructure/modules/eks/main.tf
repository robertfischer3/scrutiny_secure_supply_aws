module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  # Cluster configuration
  cluster_name                    = var.name
  cluster_version                 = var.cluster_version
  vpc_id                          = var.vpc_id
  subnet_ids                      = var.subnet_ids
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  
  # Enable OIDC for IAM roles for service accounts (IRSA)
  enable_irsa                     = var.enable_irsa
  
  # Cluster encryption configuration
  cluster_encryption_config       = var.cluster_encryption_config
  
  # KMS key for secrets encryption
  create_kms_key                  = var.create_kms_key
  kms_key_deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_kms_key_rotation         = var.enable_kms_key_rotation
  
  # EKS Managed Node Groups
  eks_managed_node_groups         = var.eks_managed_node_groups
  
  # Self Managed Node Groups
  self_managed_node_groups        = var.self_managed_node_groups
  
  # Fargate Profiles
  fargate_profiles                = var.fargate_profiles
  
  # Security Group rules
  cluster_security_group_additional_rules = var.cluster_security_group_additional_rules
  node_security_group_additional_rules    = var.node_security_group_additional_rules
  
  # AWS Auth configuration for additional IAM roles/users
  manage_aws_auth_configmap = var.manage_aws_auth_configmap
  aws_auth_roles            = var.aws_auth_roles
  aws_auth_users            = var.aws_auth_users
  
  # CloudWatch Logs configuration
  cluster_enabled_log_types = var.cluster_enabled_log_types
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  
  # Tags
  tags = var.tags
}

# AWS Load Balancer Controller - required for Harbor ingress
module "lb_controller" {
  count  = var.enable_aws_load_balancer_controller ? 1 : 0
  source = "git::https://github.com/DNXLabs/terraform-aws-eks-lb-controller.git"
  
  cluster_name                     = module.eks.cluster_name
  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  
  depends_on = [module.eks]
}

# Amazon EBS CSI Driver - required for persistent volumes
module "ebs_csi_driver" {
  count  = var.enable_amazon_eks_aws_ebs_csi_driver ? 1 : 0
  source = "git::https://github.com/DNXLabs/terraform-aws-eks-ebs-csi-driver.git"
  
  cluster_name                     = module.eks.cluster_name
  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  
  depends_on = [module.eks]
}

# Amazon EFS CSI Driver - for shared storage
module "efs_csi_driver" {
  count  = var.enable_efs_csi_driver ? 1 : 0
  source = "git::https://github.com/DNXLabs/terraform-aws-eks-efs-csi-driver.git"
  
  cluster_name                     = module.eks.cluster_name
  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  
  depends_on = [module.eks]
}

# Create EFS Storage Class
resource "kubernetes_storage_class" "efs" {
  count = var.enable_efs_csi_driver ? 1 : 0
  
  metadata {
    name = "efs-sc"
  }
  
  storage_provisioner = "efs.csi.aws.com"
  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = var.efs_file_system_id
    directoryPerms   = "700"
  }
  
  reclaim_policy         = "Retain"
  allow_volume_expansion = true
  
  depends_on = [module.efs_csi_driver]
}

# Create IAM role for Harbor to access S3
resource "aws_iam_policy" "harbor_s3_policy" {
  count       = var.create_iam_role_harbor_s3 ? 1 : 0
  name        = "harbor-s3-policy-${var.environment}"
  description = "IAM policy for Harbor to access S3 bucket"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          var.harbor_s3_bucket_arn,
          "${var.harbor_s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "harbor_s3_role" {
  count              = var.create_iam_role_harbor_s3 ? 1 : 0
  name               = "harbor-s3-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub": "system:serviceaccount:${var.harbor_namespace}:harbor-core"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "harbor_s3_policy_attachment" {
  count      = var.create_iam_role_harbor_s3 ? 1 : 0
  role       = aws_iam_role.harbor_s3_role[0].name
  policy_arn = aws_iam_policy.harbor_s3_policy[0].arn
}

# Create Kubernetes service account annotation for Harbor
resource "kubernetes_service_account" "harbor_core" {
  count = var.create_iam_role_harbor_s3 ? 1 : 0
  
  metadata {
    name      = "harbor-core"
    namespace = var.harbor_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.harbor_s3_role[0].arn
    }
  }
  
  depends_on = [aws_iam_role.harbor_s3_role]
}

# EKS Add-ons (optional)
resource "aws_eks_addon" "vpc_cni" {
  count             = var.enable_vpc_cni_addon ? 1 : 0
  cluster_name      = module.eks.cluster_name
  addon_name        = "vpc-cni"
  addon_version     = var.vpc_cni_addon_version
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  count             = var.enable_coredns_addon ? 1 : 0
  cluster_name      = module.eks.cluster_name
  addon_name        = "coredns"
  addon_version     = var.coredns_addon_version
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy" {
  count             = var.enable_kube_proxy_addon ? 1 : 0
  cluster_name      = module.eks.cluster_name
  addon_name        = "kube-proxy"
  addon_version     = var.kube_proxy_addon_version
  resolve_conflicts = "OVERWRITE"
}

# Metrics Server - required for HPA
resource "helm_release" "metrics_server" {
  count      = var.enable_metrics_server ? 1 : 0
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = var.metrics_server_version

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }

  depends_on = [module.eks]
}

# Cluster Autoscaler
resource "helm_release" "cluster_autoscaler" {
  count      = var.enable_cluster_autoscaler ? 1 : 0
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = var.cluster_autoscaler_version

  set {
    name  = "autoDiscovery.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.aws_region
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.cluster_autoscaler_irsa[0].iam_role_arn
  }

  depends_on = [module.eks]
}

# Cluster Autoscaler IRSA
module "cluster_autoscaler_irsa" {
  count   = var.enable_cluster_autoscaler ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                        = "cluster-autoscaler-${var.environment}"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }
}

# Data sources for kubectl provider
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
  
  depends_on = [module.eks.cluster_name]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
  
  depends_on = [module.eks.cluster_name]
}

# Amazon Managed Prometheus (optional)
resource "aws_prometheus_workspace" "this" {
  count = var.enable_amazon_prometheus ? 1 : 0
  alias = "eks-${var.name}-prometheus"
  
  tags = var.tags
}

# Amazon Managed Grafana (optional)
resource "aws_grafana_workspace" "this" {
  count        = var.enable_amazon_grafana ? 1 : 0
  name         = "eks-${var.name}-grafana"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  
  data_sources = ["AMAZON_PROMETHEUS"]
  
  tags = var.tags
}