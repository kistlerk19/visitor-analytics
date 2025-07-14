# S3 bucket for application assets and backups
resource "aws_s3_bucket" "assets" {
  bucket = "${var.project_name}-assets-${random_id.suffix.hex}"
  tags   = var.tags

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      tags_all
    ]
  }
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# DR S3 bucket for cross-region replication
resource "aws_s3_bucket" "assets_dr" {
  count    = var.enable_dr ? 1 : 0
  provider = aws.dr
  bucket   = "${var.project_name}-assets-dr-${random_id.suffix.hex}"
  tags     = var.tags
}

resource "aws_s3_bucket_versioning" "assets_dr" {
  count    = var.enable_dr ? 1 : 0
  provider = aws.dr
  bucket   = aws_s3_bucket.assets_dr[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# Cross-region replication configuration
resource "aws_s3_bucket_replication_configuration" "assets" {
  count      = var.enable_dr ? 1 : 0
  depends_on = [aws_s3_bucket_versioning.assets, aws_s3_bucket_versioning.assets_dr]
  role       = aws_iam_role.replication[0].arn
  bucket     = aws_s3_bucket.assets.id

  rule {
    id     = "replicate-to-dr"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.assets_dr[0].arn
      storage_class = "STANDARD_IA"
    }
  }
}

# IAM role for S3 replication
resource "aws_iam_role" "replication" {
  count = var.enable_dr ? 1 : 0
  name  = "${var.project_name}-s3-replication-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "replication" {
  count = var.enable_dr ? 1 : 0
  name  = "${var.project_name}-s3-replication-policy-${random_id.suffix.hex}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl"
        ]
        Resource = "${aws_s3_bucket.assets.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.assets.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Resource = "${aws_s3_bucket.assets_dr[0].arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication" {
  count      = var.enable_dr ? 1 : 0
  role       = aws_iam_role.replication[0].name
  policy_arn = aws_iam_policy.replication[0].arn
}

# Lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    id     = "lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}