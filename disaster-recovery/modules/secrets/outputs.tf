output "db_password" {
  description = "Database password"
  value       = random_password.db_password.result
  sensitive   = true
}

output "secret_arn" {
  description = "Secrets Manager secret ARN"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "dr_secret_arn" {
  description = "DR Secrets Manager secret ARN"
  value       = var.enable_dr ? aws_secretsmanager_secret.db_credentials_dr[0].arn : null
}

output "secret_name" {
  description = "Secrets Manager secret name"
  value       = aws_secretsmanager_secret.db_credentials.name
}