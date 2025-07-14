# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-${random_id.suffix.hex}"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-subnet-group"
  })
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-db-${random_id.suffix.hex}"

  # Engine
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  # Storage
  allocated_storage     = 20
  max_allocated_storage = 0
  storage_type          = "gp2"
  storage_encrypted     = false

  # Database
  db_name  = "visitor_analytics"
  username = "root"
  password = var.db_password

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]
  publicly_accessible    = false
  port                   = 3306

  # Backup and Maintenance
  backup_retention_period = var.enable_dr ? 7 : 0
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"
  skip_final_snapshot     = true
  deletion_protection     = false

  # Performance
  performance_insights_enabled = false
  monitoring_interval          = 0

  # Lifecycle protection
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      password,
      final_snapshot_identifier,
      status,
      tags_all
    ]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-db"
  })
}

# Read Replica for DR (only if enable_dr is true)
resource "aws_db_instance" "replica" {
  count = var.enable_dr ? 1 : 0

  identifier = "${var.project_name}-db-replica-${random_id.suffix.hex}"

  # Replica configuration
  replicate_source_db = aws_db_instance.main.arn
  instance_class      = "db.t3.micro"

  # Storage
  allocated_storage     = 20
  max_allocated_storage = 0
  storage_type          = "gp2"

  # Network (DR region)
  db_subnet_group_name   = var.dr_subnet_group_name
  vpc_security_group_ids = [var.dr_rds_security_group_id]
  publicly_accessible    = false

  # Backup
  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  # Performance
  performance_insights_enabled = false
  monitoring_interval          = 0

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-replica"
  })

  provider = aws.dr
}