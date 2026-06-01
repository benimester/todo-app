output "frontend_enable" {
  value       = var.frontend_enable
  description = "Whether to provision the CloudFront distribution for frontend hosting."
}

output "frontend_s3_bucket_path" {
  value       = var.frontend_s3_bucket_path
  description = "The path in the S3 bucket where the frontend files are hosted."
}
