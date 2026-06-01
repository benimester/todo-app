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

    k8s_api = {
      domain_name = aws_eip.bastion_eip[0].public_dns
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3_bucket"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    use_forwarded_values   = false
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  ordered_cache_behavior = [
    {
      path_pattern             = "/todos*"
      target_origin_id         = "k8s_api"
      viewer_protocol_policy   = "allow-all"
      allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods           = ["GET", "HEAD"]
      cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
      origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
      use_forwarded_values     = false
    },
    {
      path_pattern             = "/upload*"
      target_origin_id         = "k8s_api"
      viewer_protocol_policy   = "allow-all"
      allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods           = ["GET", "HEAD"]
      cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
      origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
      use_forwarded_values     = false
    },
    {
      path_pattern             = "/register*"
      target_origin_id         = "k8s_api"
      viewer_protocol_policy   = "allow-all"
      allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods           = ["GET", "HEAD"]
      cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
      origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
      use_forwarded_values     = false
    },
    {
      path_pattern             = "/token*"
      target_origin_id         = "k8s_api"
      viewer_protocol_policy   = "allow-all"
      allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods           = ["GET", "HEAD"]
      cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
      origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
      use_forwarded_values     = false
    }
  ]

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
