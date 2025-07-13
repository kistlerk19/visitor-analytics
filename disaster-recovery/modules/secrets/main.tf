# Random password for RDS
resource "random_password" "db_password" {
  length  = 16
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Secrets Manager secret for database credentials
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.project_name}-db-credentials-${random_id.suffix.hex}"
  description = "Database credentials for ${var.project_name}"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "root"
    password = random_password.db_password.result
    engine   = "mysql"
    port     = 3306
    dbname   = "visitor_analytics"
  })
}

# DR region secret (if enabled)
resource "aws_secretsmanager_secret" "db_credentials_dr" {
  count = var.enable_dr ? 1 : 0

  provider = aws.dr

  name        = "db-creds-dr-${random_id.suffix.hex}"
  description = "Database credentials for ${var.project_name} DR"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db_credentials_dr" {
  count = var.enable_dr ? 1 : 0

  provider = aws.dr

  secret_id = aws_secretsmanager_secret.db_credentials_dr[0].id
  secret_string = jsonencode({
    username = "root"
    password = random_password.db_password.result
    engine   = "mysql"
    port     = 3306
    dbname   = "visitor_analytics"
  })
}