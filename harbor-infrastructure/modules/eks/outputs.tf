output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS Kubernetes API"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider" {
  description = "The OpenID Connect identity provider (without protocol prefix)"
  value       = module.eks.oidc_provider
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  value       = module.eks.oidc_provider_arn
}

output "cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = module.eks.cluster_version
}

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = module.eks.cluster_iam_role_name
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = module.eks.node_security_group_id
}

output "cluster_primary_security_group_id" {
  description = "The ID of the cluster primary security group"
  value       = module.eks.cluster_primary_security_group_id
}

output "eks_managed_node_groups" {
  description = "Map of EKS managed node groups created"
  value       = module.eks.eks_managed_node_groups
}

output "self_managed_node_groups" {
  description = "Map of self-managed node groups created"
  value       = module.eks.self_managed_node_groups
}

output "fargate_profiles" {
  description = "Map of Fargate Profiles created"
  value       = module.eks.fargate_profiles
}

output "aws_auth_configmap_yaml" {
  description = "Formatted yaml output for aws-auth ConfigMap"
  value       = module.eks.aws_auth_configmap_yaml
}

output "kubeconfig" {
  description = "kubectl config that can be used to connect to the cluster"
  value       = module.eks.kubeconfig
  sensitive   = true
}

output "harbor_s3_role_arn" {
  description = "ARN of the IAM role used by Harbor to access S3"
  value       = var.create_iam_role_harbor_s3 ? aws_iam_role.harbor_s3_role[0].arn : ""
}

output "harbor_s3_policy_arn" {
  description = "ARN of the IAM policy used by Harbor to access S3"
  value       = var.create_iam_role_harbor_s3 ? aws_iam_policy.harbor_s3_policy[0].arn : ""
}

output "efs_storage_class_name" {
  description = "Name of the EFS storage class created"
  value       = var.enable_efs_csi_driver ? kubernetes_storage_class.efs[0].metadata[0].name : ""
}

output "prometheus_workspace_id" {
  description = "ID of the Amazon Managed Prometheus workspace"
  value       = var.enable_amazon_prometheus ? aws_prometheus_workspace.this[0].id : ""
}

output "prometheus_workspace_arn" {
  description = "ARN of the Amazon Managed Prometheus workspace"
  value       = var.enable_amazon_prometheus ? aws_prometheus_workspace.this[0].arn : ""
}

output "grafana_workspace_id" {
  description = "ID of the Amazon Managed Grafana workspace"
  value       = var.enable_amazon_grafana ? aws_grafana_workspace.this[0].id : ""
}

output "grafana_workspace_endpoint" {
  description = "Endpoint of the Amazon Managed Grafana workspace"
  value       = var.enable_amazon_grafana ? aws_grafana_workspace.this[0].endpoint : ""
}

output "load_balancer_controller_enabled" {
  description = "Whether the AWS Load Balancer Controller is enabled"
  value       = var.enable_aws_load_balancer_controller
}

output "ebs_csi_driver_enabled" {
  description = "Whether the Amazon EBS CSI driver is enabled"
  value       = var.enable_amazon_eks_aws_ebs_csi_driver
}

output "efs_csi_driver_enabled" {
  description = "Whether the Amazon EFS CSI driver is enabled"
  value       = var.enable_efs_csi_driver
}

output "metrics_server_enabled" {
  description = "Whether Metrics Server is enabled"
  value       = var.enable_metrics_server
}

output "cluster_autoscaler_enabled" {
  description = "Whether Cluster Autoscaler is enabled"
  value       = var.enable_cluster_autoscaler
}