# modules/eks/addons.tf

# Core EKS addons - managed by AWS
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

# Additional EKS addons
resource "aws_eks_addon" "aws_ebs_csi_driver" {
  count             = var.enable_amazon_eks_aws_ebs_csi_driver ? 1 : 0
  cluster_name      = module.eks.cluster_name
  addon_name        = "aws-ebs-csi-driver"
  addon_version     = var.aws_ebs_csi_driver_version
  resolve_conflicts = "OVERWRITE"
  
  # Service account role
  service_account_role_arn = module.ebs_csi_irsa_role[0].iam_role_arn
  
  depends_on = [module.eks]
}

# IRSA role for EBS CSI Driver
module "ebs_csi_irsa_role" {
  count   = var.enable_amazon_eks_aws_ebs_csi_driver ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "ebs-csi-controller-${var.environment}"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

# EFS CSI driver addon
resource "aws_eks_addon" "efs_csi_driver" {
  count             = var.enable_efs_csi_driver ? 1 : 0
  cluster_name      = module.eks.cluster_name
  addon_name        = "aws-efs-csi-driver"
  addon_version     = var.efs_csi_driver_version
  resolve_conflicts = "OVERWRITE"
  
  service_account_role_arn = module.efs_csi_irsa_role[0].iam_role_arn
  
  depends_on = [module.eks]
}

# IRSA role for EFS CSI Driver
module "efs_csi_irsa_role" {
  count   = var.enable_efs_csi_driver ? 1 : 0
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "efs-csi-controller-${var.environment}"
  
  attach_efs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }
}

# Create EFS Storage Class
resource "kubernetes_storage_class" "efs" {
  count = var.enable_efs_csi_driver && var.efs_file_system_id != "" ? 1 : 0
  
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
  
  depends_on = [aws_eks_addon.efs_csi_driver]
}

# AWS ADOT (OpenTelemetry) addon
resource "aws_eks_addon" "adot" {
  count             = var.enable_adot_addon ? 1 : 0
  cluster_name      = module.eks.cluster_name
  addon_name        = "adot"
  addon_version     = var.adot_addon_version
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