variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "name" {
  description = "Name of the WAF WebACL"
  type        = string
}

variable "scope" {
  description = "Scope of the WAF WebACL (REGIONAL or CLOUDFRONT)"
  type        = string
  default     = "REGIONAL"
  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "Scope must be either REGIONAL or CLOUDFRONT."
  }
}

variable "default_action" {
  description = "Default action for the WAF WebACL (allow or block)"
  type        = string
  default     = "allow"
  validation {
    condition     = contains(["allow", "block"], var.default_action)
    error_message = "Default action must be either allow or block."
  }
}

variable "rules" {
  description = "List of rules to be used in the WAF WebACL"
  type        = any
  default     = []
}

variable "visibility_config" {
  description = "Visibility configuration for the WAF WebACL"
  type = object({
    cloudwatch_metrics_enabled = bool
    metric_name                = string
    sampled_requests_enabled   = bool
  })
}

variable "custom_response_bodies" {
  description = "Custom response bodies for the WAF WebACL"
  type        = map(object({
    content      = string
    content_type = string
  }))
  default     = {}
}

variable "token_domains" {
  description = "List of domains to be used for token-based protection (CSRF)"
  type        = list(string)
  default     = []
}

variable "enable_captcha" {
  description = "Whether to enable CAPTCHA in the WAF WebACL"
  type        = bool
  default     = false
}

variable "captcha_immunity_time" {
  description = "Immunity time for CAPTCHA in seconds"
  type        = number
  default     = 300
}

variable "enable_challenge" {
  description = "Whether to enable Challenge in the WAF WebACL"
  type        = bool
  default     = false
}

variable "challenge_immunity_time" {
  description = "Immunity time for Challenge in seconds"
  type        = number
  default     = 300
}

variable "alb_arn" {
  description = "ARN of the ALB to associate with the WAF WebACL"
  type        = string
  default     = ""
}

variable "associate_alb" {
  description = "Whether to associate the WAF WebACL with an ALB"
  type        = bool
  default     = false
}

variable "enable_logging" {
  description = "Whether to enable logging for the WAF WebACL"
  type        = bool
  default     = false
}

variable "log_destination_arn" {
  description = "ARN of the log destination for the WAF WebACL"
  type        = string
  default     = ""
}

variable "redacted_fields" {
  description = "List of fields to redact from the logs"
  type        = list(object({
    type = string
    name = optional(string)
  }))
  default     = []
}

variable "logging_filter" {
  description = "Logging filter for the WAF WebACL"
  type        = any
  default     = null
}

variable "create_dashboard" {
  description = "Whether to create a CloudWatch dashboard for the WAF WebACL"
  type        = bool
  default     = true
}

variable "create_alarms" {
  description = "Whether to create CloudWatch alarms for the WAF WebACL"
  type        = bool
  default     = true
}

variable "blocked_requests_threshold" {
  description = "Threshold for the high blocked requests alarm"
  type        = number
  default     = 100
}

variable "alarm_actions" {
  description = "List of ARNs to notify when an alarm transitions"
  type        = list(string)
  default     = []
}

variable "allowed_ip_addresses" {
  description = "List of IP addresses to allow"
  type        = list(string)
  default     = []
}

variable "blocked_ip_addresses" {
  description = "List of IP addresses to block"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to be applied to the WAF WebACL"
  type        = map(string)
  default     = {}
}