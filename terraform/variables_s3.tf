variable "s3_enable" {
  description = "Whether to provision the S3 bucket"
  type        = bool
}

variable "s3_name" {
  description = "The name of the S3 bucket for frontend hosting"
  type        = string
}
