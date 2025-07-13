output "apache_repository_url" {
  description = "Apache ECR repository URL"
  value       = aws_ecr_repository.apache.repository_url
}

output "mysql_repository_url" {
  description = "MySQL ECR repository URL"
  value       = aws_ecr_repository.mysql.repository_url
}

output "apache_repository_name" {
  description = "Apache ECR repository name"
  value       = aws_ecr_repository.apache.name
}

output "mysql_repository_name" {
  description = "MySQL ECR repository name"
  value       = aws_ecr_repository.mysql.name
}