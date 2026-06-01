variable "frontend_enable" {
  description = "Whether to provision the CloudFront distribution for the frontend hosting"
  type        = bool
}

variable "frontend_s3_bucket_path" {
  description = "The path in the S3 bucket where the frontend files are hosted"
  type        = string
}
