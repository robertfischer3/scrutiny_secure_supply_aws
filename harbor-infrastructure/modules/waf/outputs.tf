output "web_acl_id" {
  description = "The ID of the WAF WebACL"
  value       = aws_wafv2_web_acl.main.id
}

output "web_acl_arn" {
  description = "The ARN of the WAF WebACL"
  value       = aws_wafv2_web_acl.main.arn
}

output "web_acl_capacity" {
  description = "The capacity of the WAF WebACL"
  value       = aws_wafv2_web_acl.main.capacity
}

output "web_acl_name" {
  description = "The name of the WAF WebACL"
  value       = aws_wafv2_web_acl.main.name
}

output "web_acl_default_action" {
  description = "The default action of the WAF WebACL"
  value       = var.default_action
}

output "web_acl_rules" {
  description = "The rules of the WAF WebACL"
  value       = var.rules
}

output "web_acl_scope" {
  description = "The scope of the WAF WebACL"
  value       = var.scope
}

output "web_acl_visibility_config" {
  description = "The visibility configuration of the WAF WebACL"
  value       = aws_wafv2_web_acl.main.visibility_config
}

output "allowed_ip_set_id" {
  description = "The ID of the allowed IP set"
  value       = length(var.allowed_ip_addresses) > 0 ? aws_wafv2_ip_set.allowed_ips[0].id : null
}

output "allowed_ip_set_arn" {
  description = "The ARN of the allowed IP set"
  value       = length(var.allowed_ip_addresses) > 0 ? aws_wafv2_ip_set.allowed_ips[0].arn : null
}

output "blocked_ip_set_id" {
  description = "The ID of the blocked IP set"
  value       = length(var.blocked_ip_addresses) > 0 ? aws_wafv2_ip_set.blocked_ips[0].id : null
}

output "blocked_ip_set_arn" {
  description = "The ARN of the blocked IP set"
  value       = length(var.blocked_ip_addresses) > 0 ? aws_wafv2_ip_set.blocked_ips[0].arn : null
}

output "web_acl_association_id" {
  description = "The ID of the WAF WebACL Association"
  value       = var.associate_alb && var.alb_arn != "" ? aws_wafv2_web_acl_association.main[0].id : null
}

output "web_acl_logging_configuration_id" {
  description = "The ID of the WAF WebACL Logging Configuration"
  value       = var.enable_logging && var.log_destination_arn != "" ? aws_wafv2_web_acl_logging_configuration.main[0].id : null
}

output "dashboard_name" {
  description = "The name of the CloudWatch dashboard"
  value       = var.create_dashboard ? aws_cloudwatch_dashboard.waf[0].dashboard_name : null
}

output "dashboard_arn" {
  description = "The ARN of the CloudWatch dashboard"
  value       = var.create_dashboard ? "arn:aws:cloudwatch::${data.aws_caller_identity.current.account_id}:dashboard/${aws_cloudwatch_dashboard.waf[0].dashboard_name}" : null
}

output "alarm_arn" {
  description = "The ARN of the CloudWatch alarm"
  value       = var.create_alarms ? aws_cloudwatch_metric_alarm.high_blocked_requests[0].arn : null
}