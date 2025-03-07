# Outputs for Cloudflare module

output "cloudflare_zone_id" {
  description = "The Cloudflare zone ID"
  value       = var.create_zone ? cloudflare_zone.harbor_zone[0].id : var.zone_id
}

output "harbor_dns_record" {
  description = "The full Harbor DNS record"
  value       = "${var.subdomain}.${var.domain_name}"
}
