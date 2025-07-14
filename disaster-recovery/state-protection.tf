# State protection and lifecycle management
resource "terraform_data" "deployment_marker" {
  input = {
    timestamp = timestamp()
    image_tag = var.image_tag
    enable_dr = var.enable_dr
  }

  lifecycle {
    replace_triggered_by = [
      var.image_tag,
      var.enable_dr
    ]
  }
}

# Prevent accidental deletion of critical resources
resource "aws_db_instance" "main" {
  # This is handled in the RDS module, but adding lifecycle here for extra protection
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      password,
      final_snapshot_identifier,
      latest_restorable_time,
      status
    ]
  }
}

# S3 bucket protection
resource "aws_s3_bucket" "assets" {
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      tags_all
    ]
  }
}