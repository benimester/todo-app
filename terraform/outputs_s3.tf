output "s3_enable" {
  value       = var.s3_enable
  description = "Whether to provision the S3 bucket."
}

output "s3_bucket_name" {
  value       = var.s3_name
  description = "The name of the S3 bucket for todo-app."
  depends_on  = [var.s3_enable]
}
