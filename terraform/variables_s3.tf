variable "s3_enable" {
  description = "Whether to provision the S3 bucket"
  type        = bool
}

variable "s3_name" {
  description = "The name of the S3 bucket for frontend hosting"
  type        = string
}

variable "media_service_username" {
  description = "IAM username for media service access to S3"
  type        = string
}