# harbor-infrastructure/modules/iam/variables.tf

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "admin_principals" {
  description = "List of IAM ARNs that can assume the admin roles"
  type        = list(string)
  default     = [] 
}

variable "operator_principals" {
  description = "List of IAM ARNs that can assume the operator roles"
  type        = list(string)
  default     = []
}

variable "service_principals" {
  description = "List of IAM ARNs (service accounts, users, roles) that can assume the service roles"
  type        = list(string)
  default     = []
}

variable "harbor_s3_bucket_arn" {
  description = "ARN of the S3 bucket used by Harbor"
  type        = string
  default     = ""
}

variable "create_instance_profiles" {
  description = "Whether to create instance profiles for the IAM roles"
  type        = bool
  default     = false
}

variable "enable_cross_account_access" {
  description = "Whether to enable cross-account access for the roles"
  type        = bool
  default     = false
}

variable "trusted_account_ids" {
  description = "List of AWS account IDs trusted to assume roles (if cross-account access is enabled)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Map of tags to add to all resources"
  type        = map(string)
  default     = {}
}