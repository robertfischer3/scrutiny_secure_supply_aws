include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/waf"
}

inputs = {
  name               = "harbor-waf-${local.environment}"
  scope              = "REGIONAL"
  
  # Default actions
  default_action     = "allow"
  visibility_config  = {
    cloudwatch_metrics_enabled = true
    metric_name                = "harbor-waf-${local.environment}"
    sampled_requests_enabled   = true
  }
  
  # WAF rules
  rules = [
    {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 10
      override_action = "none"
      
      statement = {
        managed_rule_group_statement = {
          name        = "AWSManagedRulesCommonRuleSet"
          vendor_name = "AWS"
        }
      }
      
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesCommonRuleSet"
        sampled_requests_enabled   = true
      }
    },
    {
      name     = "AWSManagedRulesKnownBadInputsRuleSet"
      priority = 20
      override_action = "none"
      
      statement = {
        managed_rule_group_statement = {
          name        = "AWSManagedRulesKnownBadInputsRuleSet"
          vendor_name = "AWS"
        }
      }
      
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
        sampled_requests_enabled   = true
      }
    },
    {
      name     = "AWSManagedRulesSQLiRuleSet"
      priority = 30
      override_action = "none"
      
      statement = {
        managed_rule_group_statement = {
          name        = "AWSManagedRulesSQLiRuleSet"
          vendor_name = "AWS"
        }
      }
      
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesSQLiRuleSet"
        sampled_requests_enabled   = true
      }
    },
    {
      name     = "RateLimit"
      priority = 40
      action   = "block"
      
      statement = {
        rate_based_statement = {
          limit              = 1000
          aggregate_key_type = "IP"
        }
      }
      
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "RateLimit"
        sampled_requests_enabled   = true
      }
    }
  ]
}