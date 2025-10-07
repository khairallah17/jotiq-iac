resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "OAI for ${var.domain_name}"
}

locals {
  cache_policy_id = var.cache_policy_id != null ? var.cache_policy_id : "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
  origin_id       = "s3-${var.s3_bucket_domain_name}"
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.comment
  default_root_object = var.default_root_object
  price_class         = var.price_class
  web_acl_id          = var.web_acl_arn

  aliases = var.aliases

  origin {
    domain_name = var.s3_bucket_domain_name
    origin_id   = local.origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.origin_id

    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = local.cache_policy_id

    compress = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  logging_config {
    bucket = var.log_bucket_domain_name
    prefix = var.log_prefix
    include_cookies = false
  }

  tags = var.tags
}
