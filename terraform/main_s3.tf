# -----------------------------------------------------------------------------
# S3
# -----------------------------------------------------------------------------

module "s3_bucket" {
  count   = var.s3_enable ? 1 : 0
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket        = var.s3_name
  force_destroy = true
}

data "aws_iam_policy_document" "s3_object_access_policy" {
  count = var.s3_enable ? 1 : 0

  statement {
    actions   = ["s3:GetObject", "s3:ListBucket", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${module.s3_bucket[0].s3_bucket_arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["://amazonaws.com"]
    }
  }
}
