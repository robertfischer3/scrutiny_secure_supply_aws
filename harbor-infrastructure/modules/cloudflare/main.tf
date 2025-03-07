# Cloudflare module for Harbor S2C2F implementation

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# Cloudflare zone for the domain
resource "cloudflare_zone" "harbor_zone" {
  count = var.create_zone ? 1 : 0
  zone  = var.domain_name
}

# DNS record for Harbor
resource "cloudflare_record" "harbor" {
  zone_id = var.create_zone ? cloudflare_zone.harbor_zone[0].id : var.zone_id
  name    = var.subdomain
  value   = var.origin_address
  type    = "CNAME"
  proxied = true
}

# WAF configuration
resource "cloudflare_ruleset" "harbor_waf" {
  zone_id     = var.create_zone ? cloudflare_zone.harbor_zone[0].id : var.zone_id
  name        = "Harbor Registry Protection"
  description = "WAF rules to protect Harbor registry"
  kind        = "zone"
  phase       = "http_request_firewall_managed"

  rules {
    action = "execute"
    action_parameters {
      id = "efb7b8c949ac4650a09736fc376e9aee"
    }
    expression  = "true"
    description = "OWASP Core Ruleset"
    enabled     = true
  }
}

# Zero Trust Access policy (if enabled)
resource "cloudflare_access_application" "harbor_app" {
  count       = var.enable_zero_trust ? 1 : 0
  zone_id     = var.create_zone ? cloudflare_zone.harbor_zone[0].id : var.zone_id
  name        = "Harbor Registry"
  domain      = "${var.subdomain}.${var.domain_name}"
  session_duration = "24h"
}

resource "cloudflare_access_policy" "harbor_policy" {
  count             = var.enable_zero_trust ? 1 : 0
  application_id    = cloudflare_access_application.harbor_app[0].id
  zone_id           = var.create_zone ? cloudflare_zone.harbor_zone[0].id : var.zone_id
  name              = "Harbor Access"
  precedence        = 1
  decision          = "allow"
  
  include {
    group = var.allowed_groups
  }
}

# Rate limiting rule
resource "cloudflare_rate_limit" "harbor_rate_limit" {
  zone_id           = var.create_zone ? cloudflare_zone.harbor_zone[0].id : var.zone_id
  threshold         = var.rate_limit_threshold
  period            = var.rate_limit_period
  match {
    request {
      url_pattern   = "*"
      schemes       = ["HTTP", "HTTPS"]
      methods       = ["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD"]
    }
  }
  action {
    mode           = "simulate"
    timeout        = 60
    response {
      content_type = "text/plain"
      body         = "You have exceeded the rate limit. Please try again later."
    }
  }
  disabled          = false
  description       = "Rate limiting for Harbor registry"
}

# Page rules
resource "cloudflare_page_rule" "force_ssl" {
  zone_id  = var.create_zone ? cloudflare_zone.harbor_zone[0].id : var.zone_id
  target   = "*.${var.domain_name}/*"
  priority = 1

  actions {
    always_use_https = true
  }
}
