resource "aws_wafv2_web_acl" "main" {
  name        = var.name
  description = "WAF Web ACL for Harbor S2C2F compliance"
  scope       = var.scope

  default_action {
    dynamic "allow" {
      for_each = var.default_action == "allow" ? [1] : []
      content {}
    }

    dynamic "block" {
      for_each = var.default_action == "block" ? [1] : []
      content {}
    }
  }

  # WAF rules defined via variables
  dynamic "rule" {
    for_each = var.rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      # Override action for managed rule groups
      dynamic "override_action" {
        for_each = lookup(rule.value, "override_action", null) != null ? [1] : []
        content {
          dynamic "none" {
            for_each = rule.value.override_action == "none" ? [1] : []
            content {}
          }
          dynamic "count" {
            for_each = rule.value.override_action == "count" ? [1] : []
            content {}
          }
        }
      }

      # Action for regular rules
      dynamic "action" {
        for_each = lookup(rule.value, "action", null) != null ? [1] : []
        content {
          dynamic "allow" {
            for_each = rule.value.action == "allow" ? [1] : []
            content {}
          }
          dynamic "block" {
            for_each = rule.value.action == "block" ? [1] : []
            content {}
          }
          dynamic "count" {
            for_each = rule.value.action == "count" ? [1] : []
            content {}
          }
        }
      }

      # Statement configuration
      statement {
        # Managed rule group statement
        dynamic "managed_rule_group_statement" {
          for_each = lookup(rule.value.statement, "managed_rule_group_statement", null) != null ? [rule.value.statement.managed_rule_group_statement] : []
          content {
            name        = managed_rule_group_statement.value.name
            vendor_name = managed_rule_group_statement.value.vendor_name

            # Optional scope down statement
            dynamic "scope_down_statement" {
              for_each = lookup(managed_rule_group_statement.value, "scope_down_statement", null) != null ? [managed_rule_group_statement.value.scope_down_statement] : []
              content {
                # Include nested statements if provided
                dynamic "byte_match_statement" {
                  for_each = lookup(scope_down_statement.value, "byte_match_statement", null) != null ? [scope_down_statement.value.byte_match_statement] : []
                  content {
                    field_to_match {
                      dynamic "uri_path" {
                        for_each = lookup(byte_match_statement.value.field_to_match, "uri_path", null) != null ? [1] : []
                        content {}
                      }
                      dynamic "single_header" {
                        for_each = lookup(byte_match_statement.value.field_to_match, "single_header", null) != null ? [byte_match_statement.value.field_to_match.single_header] : []
                        content {
                          name = single_header.value.name
                        }
                      }
                      dynamic "query_string" {
                        for_each = lookup(byte_match_statement.value.field_to_match, "query_string", null) != null ? [1] : []
                        content {}
                      }
                    }
                    positional_constraint = byte_match_statement.value.positional_constraint
                    search_string         = byte_match_statement.value.search_string
                    text_transformation {
                      priority = byte_match_statement.value.text_transformation.priority
                      type     = byte_match_statement.value.text_transformation.type
                    }
                  }
                }
              }
            }

            # Optional excluded rules
            dynamic "excluded_rule" {
              for_each = lookup(managed_rule_group_statement.value, "excluded_rules", [])
              content {
                name = excluded_rule.value
              }
            }
          }
        }

        # Rate-based statement
        dynamic "rate_based_statement" {
          for_each = lookup(rule.value.statement, "rate_based_statement", null) != null ? [rule.value.statement.rate_based_statement] : []
          content {
            limit              = rate_based_statement.value.limit
            aggregate_key_type = lookup(rate_based_statement.value, "aggregate_key_type", "IP")
            
            # Optional scope down statement for rate-based rules
            dynamic "scope_down_statement" {
              for_each = lookup(rate_based_statement.value, "scope_down_statement", null) != null ? [rate_based_statement.value.scope_down_statement] : []
              content {
                # Include nested statements if provided
                dynamic "byte_match_statement" {
                  for_each = lookup(scope_down_statement.value, "byte_match_statement", null) != null ? [scope_down_statement.value.byte_match_statement] : []
                  content {
                    field_to_match {
                      dynamic "uri_path" {
                        for_each = lookup(byte_match_statement.value.field_to_match, "uri_path", null) != null ? [1] : []
                        content {}
                      }
                      dynamic "single_header" {
                        for_each = lookup(byte_match_statement.value.field_to_match, "single_header", null) != null ? [byte_match_statement.value.field_to_match.single_header] : []
                        content {
                          name = single_header.value.name
                        }
                      }
                    }
                    positional_constraint = byte_match_statement.value.positional_constraint
                    search_string         = byte_match_statement.value.search_string
                    text_transformation {
                      priority = byte_match_statement.value.text_transformation.priority
                      type     = byte_match_statement.value.text_transformation.type
                    }
                  }
                }
              }
            }
          }
        }

        # IP set reference statement
        dynamic "ip_set_reference_statement" {
          for_each = lookup(rule.value.statement, "ip_set_reference_statement", null) != null ? [rule.value.statement.ip_set_reference_statement] : []
          content {
            arn = ip_set_reference_statement.value.arn
          }
        }

        # Geo match statement
        dynamic "geo_match_statement" {
          for_each = lookup(rule.value.statement, "geo_match_statement", null) != null ? [rule.value.statement.geo_match_statement] : []
          content {
            country_codes = geo_match_statement.value.country_codes
          }
        }

        # AND statement
        dynamic "and_statement" {
          for_each = lookup(rule.value.statement, "and_statement", null) != null ? [rule.value.statement.and_statement] : []
          content {
            dynamic "statement" {
              for_each = and_statement.value.statements
              content {
                # Nested byte match statement in AND
                dynamic "byte_match_statement" {
                  for_each = lookup(statement.value, "byte_match_statement", null) != null ? [statement.value.byte_match_statement] : []
                  content {
                    field_to_match {
                      dynamic "uri_path" {
                        for_each = lookup(byte_match_statement.value.field_to_match, "uri_path", null) != null ? [1] : []
                        content {}
                      }
                      dynamic "single_header" {
                        for_each = lookup(byte_match_statement.value.field_to_match, "single_header", null) != null ? [byte_match_statement.value.field_to_match.single_header] : []
                        content {
                          name = single_header.value.name
                        }
                      }
                    }
                    positional_constraint = byte_match_statement.value.positional_constraint
                    search_string         = byte_match_statement.value.search_string
                    text_transformation {
                      priority = byte_match_statement.value.text_transformation.priority
                      type     = byte_match_statement.value.text_transformation.type
                    }
                  }
                }
                
                # Nested IP set reference statement in AND
                dynamic "ip_set_reference_statement" {
                  for_each = lookup(statement.value, "ip_set_reference_statement", null) != null ? [statement.value.ip_set_reference_statement] : []
                  content {
                    arn = ip_set_reference_statement.value.arn
                  }
                }
              }
            }
          }
        }

        # OR statement
        dynamic "or_statement" {
          for_each = lookup(rule.value.statement, "or_statement", null) != null ? [rule.value.statement.or_statement] : []
          content {
            dynamic "statement" {
              for_each = or_statement.value.statements
              content {
                # Nested byte match statement in OR
                dynamic "byte_match_statement" {
                  for_each = lookup(statement.value, "byte_match_statement", null) != null ? [statement.value.byte_match_statement] : []
                  content {
                    field_to_match {
                      dynamic "uri_path" {
                        for_each = lookup(byte_match_statement.value.field_to_match, "uri_path", null) != null ? [1] : []
                        content {}
                      }
                      dynamic "single_header" {
                        for_each = lookup(byte_match_statement.value.field_to_match, "single_header", null) != null ? [byte_match_statement.value.field_to_match.single_header] : []
                        content {
                          name = single_header.value.name
                        }
                      }
                    }
                    positional_constraint = byte_match_statement.value.positional_constraint
                    search_string         = byte_match_statement.value.search_string
                    text_transformation {
                      priority = byte_match_statement.value.text_transformation.priority
                      type     = byte_match_statement.value.text_transformation.type
                    }
                  }
                }
                
                # Nested geo match statement in OR
                dynamic "geo_match_statement" {
                  for_each = lookup(statement.value, "geo_match_statement", null) != null ? [statement.value.geo_match_statement] : []
                  content {
                    country_codes = geo_match_statement.value.country_codes
                  }
                }
              }
            }
          }
        }
      }

      # Visibility configuration for each rule
      visibility_config {
        cloudwatch_metrics_enabled = lookup(rule.value.visibility_config, "cloudwatch_metrics_enabled", true)
        metric_name                = lookup(rule.value.visibility_config, "metric_name", "${var.name}-${rule.value.name}")
        sampled_requests_enabled   = lookup(rule.value.visibility_config, "sampled_requests_enabled", true)
      }
    }
  }

  # Custom response body configurations
  dynamic "custom_response_body" {
    for_each = var.custom_response_bodies
    content {
      key          = custom_response_body.key
      content      = custom_response_body.value.content
      content_type = custom_response_body.value.content_type
    }
  }

  # WAF token domains (for CSRF protection)
  dynamic "token_domains" {
    for_each = length(var.token_domains) > 0 ? [1] : []
    content {
      domains = var.token_domains
    }
  }

  # Captcha configuration
  dynamic "captcha_config" {
    for_each = var.enable_captcha ? [1] : []
    content {
      immunity_time_property {
        immunity_time = var.captcha_immunity_time
      }
    }
  }

  # Challenge configuration
  dynamic "challenge_config" {
    for_each = var.enable_challenge ? [1] : []
    content {
      immunity_time_property {
        immunity_time = var.challenge_immunity_time
      }
    }
  }

  # Web ACL Visibility Configuration
  visibility_config {
    cloudwatch_metrics_enabled = lookup(var.visibility_config, "cloudwatch_metrics_enabled", true)
    metric_name                = lookup(var.visibility_config, "metric_name", var.name)
    sampled_requests_enabled   = lookup(var.visibility_config, "sampled_requests_enabled", true)
  }

  tags = merge(
    var.tags,
    {
      Name        = var.name
      Environment = var.environment
    }
  )
}

# Optional IP Sets for allow/deny lists
resource "aws_wafv2_ip_set" "allowed_ips" {
  count              = length(var.allowed_ip_addresses) > 0 ? 1 : 0
  name               = "${var.name}-allowed-ips"
  description        = "Allowed IP addresses for ${var.name}"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.allowed_ip_addresses

  tags = merge(
    var.tags,
    {
      Name        = "${var.name}-allowed-ips"
      Environment = var.environment
    }
  )
}

resource "aws_wafv2_ip_set" "blocked_ips" {
  count              = length(var.blocked_ip_addresses) > 0 ? 1 : 0
  name               = "${var.name}-blocked-ips"
  description        = "Blocked IP addresses for ${var.name}"
  scope              = var.scope
  ip_address_version = "IPV4"
  addresses          = var.blocked_ip_addresses

  tags = merge(
    var.tags,
    {
      Name        = "${var.name}-blocked-ips"
      Environment = var.environment
    }
  )
}

# Associate WAF with ALB (if enabled and ALB ARN provided)
resource "aws_wafv2_web_acl_association" "main" {
  count        = var.associate_alb && var.alb_arn != "" ? 1 : 0
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

# Logging configuration (optional)
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  count                   = var.enable_logging && var.log_destination_arn != "" ? 1 : 0
  resource_arn            = aws_wafv2_web_acl.main.arn
  log_destination_configs = [var.log_destination_arn]

  dynamic "redacted_fields" {
    for_each = length(var.redacted_fields) > 0 ? [1] : []
    content {
      dynamic "single_header" {
        for_each = [for f in var.redacted_fields : f if f.type == "single_header"]
        content {
          name = single_header.value.name
        }
      }
      
      dynamic "method" {
        for_each = [for f in var.redacted_fields : f if f.type == "method"]
        content {}
      }
      
      dynamic "query_string" {
        for_each = [for f in var.redacted_fields : f if f.type == "query_string"]
        content {}
      }
      
      dynamic "uri_path" {
        for_each = [for f in var.redacted_fields : f if f.type == "uri_path"]
        content {}
      }
    }
  }

  dynamic "logging_filter" {
    for_each = var.logging_filter != null ? [var.logging_filter] : []
    content {
      default_behavior = logging_filter.value.default_behavior

      dynamic "filter" {
        for_each = logging_filter.value.filters
        content {
          behavior = filter.value.behavior
          requirement = filter.value.requirement

          dynamic "condition" {
                for_each = filter.value.conditions
                content {

                  dynamic "action_condition" {
                    for_each = lookup(condition.value, "action_condition", null) != null ? [condition.value.action_condition] : []
                    content {
                      action = action_condition.value.action
                    }
                  }
                  
                  dynamic "label_name_condition" {
                    for_each = lookup(condition.value, "label_name_condition", null) != null ? [condition.value.label_name_condition] : []
                    content {
                      label_name = label_name_condition.value.label_name
                    }
                  }
                }
        }
      }
    }
  }
}
}
# CloudWatch dashboard for WAF metrics
resource "aws_cloudwatch_dashboard" "waf" {
  count          = var.create_dashboard ? 1 : 0
  dashboard_name = "${var.name}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/WAFV2", "AllowedRequests", "WebACL", var.name, "Region", data.aws_region.current.name],
            ["AWS/WAFV2", "BlockedRequests", "WebACL", var.name, "Region", data.aws_region.current.name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Allowed vs Blocked Requests"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/WAFV2", "CountedRequests", "WebACL", var.name, "Region", data.aws_region.current.name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Counted Requests"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        properties = {
          metrics = [
            ["AWS/WAFV2", "RequestsWithValidToken", "WebACL", var.name, "Region", data.aws_region.current.name],
            ["AWS/WAFV2", "ChallengeRequests", "WebACL", var.name, "Region", data.aws_region.current.name],
            ["AWS/WAFV2", "CaptchaRequests", "WebACL", var.name, "Region", data.aws_region.current.name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Challenge and CAPTCHA Metrics"
          period  = 300
        }
      }
    ]
  })
}

# Create CloudWatch alarms for WAF events
resource "aws_cloudwatch_metric_alarm" "high_blocked_requests" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "${var.name}-high-blocked-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = 300
  statistic           = "Sum"
  threshold           = var.blocked_requests_threshold
  alarm_description   = "High number of blocked requests by WAF"
  
  dimensions = {
    WebACL = var.name
    Region = data.aws_region.current.name
  }
  
  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions
}

# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}