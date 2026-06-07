# -----------------------------------------------------------------------------
# S3
# -----------------------------------------------------------------------------

module "s3_bucket" {
  count   = var.s3_enable ? 1 : 0
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket        = var.s3_name
  force_destroy = true

  block_public_acls  = true
  ignore_public_acls = true

  block_public_policy     = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "s3_object_access_policy" {
  count = var.s3_enable ? 1 : 0

  # CloudFront full access for CDN + frontend serving
  statement {
    actions = ["s3:GetObject", "s3:ListBucket", "s3:PutObject", "s3:DeleteObject"]

    resources = [
      module.s3_bucket[0].s3_bucket_arn,
      "${module.s3_bucket[0].s3_bucket_arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
  }

  # Public read — user-uploaded media files
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3_bucket[0].s3_bucket_arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

# media-service access

resource "aws_iam_user" "media_service_user" {
  name = var.media_service_username
}

resource "aws_iam_access_key" "media_service_key" {
  user = aws_iam_user.media_service_user.name
}

resource "aws_iam_user_policy" "media_s3_policy" {
  name = "media-s3-access"
  user = aws_iam_user.media_service_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          module.s3_bucket[0].s3_bucket_arn,
          "${module.s3_bucket[0].s3_bucket_arn}/*"
        ]
      }
    ]
  })
}
