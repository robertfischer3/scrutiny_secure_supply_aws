# modules/eks/main.tf

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

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
  
  # CloudWatch Logs configuration
  cluster_enabled_log_types = var.cluster_enabled_log_types
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  
  # Tags
  tags = var.tags
}

# AWS Load Balancer Controller - required for Harbor ingress
module "lb_controller" {
  count  = var.enable_aws_load_balancer_controller ? 1 : 0
  source = "terraform-aws-modules/eks-lb-controller"
  
  cluster_name                     = module.eks.cluster_name
  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  
  depends_on = [module.eks]
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

resource "aws_eks_pod_identity_association" "harbor_core" {
  count           = var.enable_pod_identity && var.create_iam_role_harbor_s3 ? 1 : 0
  cluster_name    = module.eks.cluster_name
  namespace       = var.harbor_namespace
  service_account = "harbor-core"
  role_arn        = aws_iam_role.harbor_s3_role[0].arn
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