variable "name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster (private subnets recommended)"
  type        = list(string)
}

variable "cluster_endpoint_private_access" {
  description = "Whether the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "enable_irsa" {
  description = "Whether to enable IAM Roles for Service Accounts"
  type        = bool
  default     = true
}

variable "create_kms_key" {
  description = "Whether to create a KMS key for secrets encryption"
  type        = bool
  default     = false
}

variable "kms_key_deletion_window_in_days" {
  description = "Number of days before KMS key is deleted"
  type        = number
  default     = 30
}

variable "enable_kms_key_rotation" {
  description = "Whether to enable KMS key rotation"
  type        = bool
  default     = true
}

variable "cluster_encryption_config" {
  description = "Configuration for cluster encryption"
  type        = list(object({
    provider_key_arn = string
    resources        = list(string)
  }))
  default     = []
}

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions"
  type        = any
  default     = {}
}

variable "self_managed_node_groups" {
  description = "Map of self-managed node group definitions"
  type        = any
  default     = {}
}

variable "fargate_profiles" {
  description = "Map of Fargate profile definitions"
  type        = any
  default     = {}
}

variable "cluster_security_group_additional_rules" {
  description = "Additional security group rules for the EKS cluster"
  type        = any
  default     = {}
}

variable "node_security_group_additional_rules" {
  description = "Additional security group rules for the EKS node groups"
  type        = any
  default     = {}
}

# Add support for EKS Pod Identity (newer alternative to IRSA)
variable "enable_pod_identity" {
  description = "Whether to enable EKS Pod Identity"
  type        = bool
  default     = false
}

variable "cluster_security_group_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the cluster API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Update this default in production
}

# Update eks_managed_node_groups configuration with more options for taints
variable "node_group_taints" {
  description = "Map of node group taints"
  type        = any
  default     = {}
}


variable "manage_aws_auth_configmap" {
  description = "Whether to manage the aws-auth ConfigMap"
  type        = bool
  default     = true
}

variable "aws_auth_roles" {
  description = "List of IAM roles to add to the aws-auth ConfigMap"
  type        = list(any)
  default     = []
}

variable "aws_auth_users" {
  description = "List of IAM users to add to the aws-auth ConfigMap"
  type        = list(any)
  default     = []
}

variable "cluster_enabled_log_types" {
  description = "List of log types to enable for the EKS cluster"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain CloudWatch Logs"
  type        = number
  default     = 90
}

variable "enable_aws_load_balancer_controller" {
  description = "Whether to enable the AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "enable_amazon_eks_aws_ebs_csi_driver" {
  description = "Whether to enable the Amazon EBS CSI driver"
  type        = bool
  default     = true
}

variable "enable_efs_csi_driver" {
  description = "Whether to enable the Amazon EFS CSI driver"
  type        = bool
  default     = true
}

variable "efs_file_system_id" {
  description = "ID of the EFS file system to use with the EFS CSI driver"
  type        = string
  default     = ""
}

variable "create_iam_role_harbor_s3" {
  description = "Whether to create an IAM role for Harbor to access S3"
  type        = bool
  default     = true
}

variable "harbor_s3_bucket_arn" {
  description = "ARN of the S3 bucket for Harbor storage"
  type        = string
  default     = ""
}

variable "harbor_namespace" {
  description = "Kubernetes namespace for Harbor"
  type        = string
  default     = "harbor"
}

variable "enable_vpc_cni_addon" {
  description = "Whether to enable the VPC CNI add-on"
  type        = bool
  default     = true
}

variable "vpc_cni_addon_version" {
  description = "Version of the VPC CNI add-on"
  type        = string
  default     = "v1.14.0-eksbuild.1"
}

variable "enable_coredns_addon" {
  description = "Whether to enable the CoreDNS add-on"
  type        = bool
  default     = true
}

variable "coredns_addon_version" {
  description = "Version of the CoreDNS add-on"
  type        = string
  default     = "v1.10.1-eksbuild.1"
}

variable "enable_kube_proxy_addon" {
  description = "Whether to enable the kube-proxy add-on"
  type        = bool
  default     = true
}

variable "kube_proxy_addon_version" {
  description = "Version of the kube-proxy add-on"
  type        = string
  default     = "v1.28.1-eksbuild.1"
}

variable "enable_metrics_server" {
  description = "Whether to enable Metrics Server"
  type        = bool
  default     = true
}

variable "metrics_server_version" {
  description = "Version of Metrics Server Helm chart"
  type        = string
  default     = "3.10.0"
}

variable "enable_cluster_autoscaler" {
  description = "Whether to enable Cluster Autoscaler"
  type        = bool
  default     = true
}

variable "aws_ebs_csi_driver_version" {
  description = "Version of the AWS EBS CSI driver addon"
  type        = string
  default     = "v1.26.0-eksbuild.1"
}

variable "adot_addon_version" {
  description = "Version of the AWS Distro for OpenTelemetry addon"
  type        = string
  default     = "v0.90.0-eksbuild.1"
}

variable "enable_adot_addon" {
  description = "Whether to enable the AWS Distro for OpenTelemetry addon"
  type        = bool
  default     = false
}

variable "cluster_autoscaler_version" {
  description = "Version of Cluster Autoscaler Helm chart"
  type        = string
  default     = "9.29.0"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "enable_amazon_prometheus" {
  description = "Whether to enable Amazon Managed Service for Prometheus"
  type        = bool
  default     = false
}

variable "enable_amazon_grafana" {
  description = "Whether to enable Amazon Managed Grafana"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}