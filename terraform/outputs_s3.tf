output "s3_enable" {
  value       = var.s3_enable
  description = "Whether to provision the S3 bucket."
}

output "s3_bucket_name" {
  value       = var.s3_name
  description = "The name of the S3 bucket for todo-app."
  depends_on  = [var.s3_enable]
}

output "media_service_username" {
  value       = aws_iam_user.media_service_user.name
  description = "IAM username for media service access to S3."
  depends_on  = [aws_iam_user.media_service_user]
}

output "media_aws_access_key_id" {
  value     = aws_iam_access_key.media_service_key.id
  sensitive = true
}

output "media_aws_secret_access_key" {
  value     = aws_iam_access_key.media_service_key.secret
  sensitive = true
}
