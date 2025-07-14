output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = var.domain_name != "" ? aws_route53_zone.main[0].zone_id : null
}

output "name_servers" {
  description = "Route53 name servers"
  value       = var.domain_name != "" ? aws_route53_zone.main[0].name_servers : null
}

output "health_check_id" {
  description = "Route53 health check ID"
  value       = var.domain_name != "" ? aws_route53_health_check.primary[0].id : null
}