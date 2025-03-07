include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/cloudflare"
}

dependency "harbor" {
  config_path = "../harbor"
}

inputs = {
  domain_name    = "example.com"
  subdomain      = "harbor-prod"
  origin_address = dependency.harbor.outputs.load_balancer_hostname
  
  # Don't create a zone by default, use an existing one
  create_zone    = false
  zone_id        = "your-cloudflare-zone-id"
  
  # Zero Trust settings
  enable_zero_trust = true
  allowed_groups    = ["harbor-admins", "developers"]
  
  # Rate limiting
  rate_limit_threshold = 1000
  rate_limit_period    = 60
}
