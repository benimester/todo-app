# -----------------------------------------------------------------------------
# Frontend
# -----------------------------------------------------------------------------

module "cloudfront" {
  count   = var.frontend_enable && var.s3_enable ? 1 : 0
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 4.0"

  comment             = "Frontend CDN distribution"
  enabled             = true
  default_root_object = "index.html"

  create_origin_access_control = true
  origin_access_control = {
    s3_oac = {
      description      = "CloudFront access to S3"
      origin_type      = "s3"
      signing_behavior = "always"
      signing_protocol = "sigv4"
    }
  }

  origin = {
    s3_bucket = {
      domain_name           = module.s3_bucket[0].s3_bucket_bucket_regional_domain_name
      origin_path           = var.frontend_s3_bucket_path
      origin_access_control = "s3_oac"
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3_bucket"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]

    use_forwarded_values = false
  }

  custom_error_response = [{
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
    }, {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }]
}

resource "aws_s3_bucket_policy" "allow_s3_access_to_cloudfront" {
  count  = var.frontend_enable && var.s3_enable ? 1 : 0
  bucket = module.s3_bucket[0].s3_bucket_id
  policy = data.aws_iam_policy_document.s3_object_access_policy[0].json
}
