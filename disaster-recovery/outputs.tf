output "primary_alb_dns" {
  description = "Primary region ALB DNS name"
  value       = module.primary_ecs.alb_dns_name
}

output "primary_db_endpoint" {
  description = "Primary database endpoint"
  value       = module.primary_rds.db_endpoint
}

output "dr_alb_dns" {
  description = "DR region ALB DNS name"
  value       = var.enable_dr ? module.dr_ecs[0].alb_dns_name : null
}

output "dr_db_endpoint" {
  description = "DR database endpoint"
  value       = module.primary_rds.replica_endpoint
}

output "primary_ecr_apache" {
  description = "Primary Apache ECR repository URL"
  value       = module.primary_ecr.apache_repository_url
}

output "dr_ecr_apache" {
  description = "DR Apache ECR repository URL"
  value       = var.enable_dr ? module.dr_ecr[0].apache_repository_url : null
}

output "primary_secrets_arn" {
  description = "Primary secrets ARN"
  value       = module.primary_secrets.secret_arn
}

output "primary_secrets_name" {
  description = "Primary secrets name"
  value       = module.primary_secrets.secret_name
}

output "s3_assets_bucket" {
  description = "S3 assets bucket name"
  value       = module.primary_s3.assets_bucket_name
}

output "dr_s3_assets_bucket" {
  description = "DR S3 assets bucket name"
  value       = module.primary_s3.dr_assets_bucket_name
}

output "lambda_dr_function" {
  description = "DR automation Lambda function name"
  value       = module.primary_lambda.dr_automation_function_name
}

output "lambda_health_function" {
  description = "Health monitor Lambda function name"
  value       = module.primary_lambda.health_monitor_function_name
}

output "route53_hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = module.primary_route53.hosted_zone_id
}

output "route53_name_servers" {
  description = "Route53 name servers"
  value       = module.primary_route53.name_servers
}