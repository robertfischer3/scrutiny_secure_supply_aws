# Variables for Cloudflare module

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "domain_name" {
  description = "The domain name to use for Harbor"
  type        = string
}

variable "subdomain" {
  description = "The subdomain for Harbor"
  type        = string
  default     = "harbor"
}

variable "origin_address" {
  description = "The origin address (ALB DNS name) for Harbor"
  type        = string
}

variable "create_zone" {
  description = "Whether to create a new Cloudflare zone"
  type        = bool
  default     = false
}

variable "zone_id" {
  description = "Cloudflare zone ID if not creating a new zone"
  type        = string
  default     = ""
}

variable "enable_zero_trust" {
  description = "Whether to enable Cloudflare Zero Trust"
  type        = bool
  default     = false
}

variable "allowed_groups" {
  description = "List of groups allowed to access Harbor through Zero Trust"
  type        = list(string)
  default     = []
}

variable "rate_limit_threshold" {
  description = "Number of requests before rate limiting kicks in"
  type        = number
  default     = 1000
}

variable "rate_limit_period" {
  description = "The time period in seconds for rate limiting"
  type        = number
  default     = 60
}
