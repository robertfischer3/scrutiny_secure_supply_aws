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

# Add any new addons here
resource "aws_eks_addon" "adot" {
  count             = var.enable_adot_addon ? 1 : 0
  cluster_name      = module.eks.cluster_name
  addon_name        = "adot"
  addon_version     = var.adot_addon_version
  resolve_conflicts = "OVERWRITE"
}