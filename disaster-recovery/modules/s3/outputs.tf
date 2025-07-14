output "assets_bucket_name" {
  description = "Name of the assets S3 bucket"
  value       = aws_s3_bucket.assets.bucket
}

output "assets_bucket_arn" {
  description = "ARN of the assets S3 bucket"
  value       = aws_s3_bucket.assets.arn
}

output "dr_assets_bucket_name" {
  description = "Name of the DR assets S3 bucket"
  value       = var.enable_dr ? aws_s3_bucket.assets_dr[0].bucket : null
}

output "dr_assets_bucket_arn" {
  description = "ARN of the DR assets S3 bucket"
  value       = var.enable_dr ? aws_s3_bucket.assets_dr[0].arn : null
}