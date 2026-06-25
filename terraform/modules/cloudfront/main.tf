resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "VastraCo ${var.environment} distribution"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  aliases             = [var.domain_name, "www.${var.domain_name}"]
  web_acl_id          = var.waf_web_acl_arn

  ############################################################################
  # Origin 1 - ALB (dynamic API traffic)
  ############################################################################
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "alb-dynamic"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  ############################################################################
  # Origin 2 - S3 Product Images (static assets via OAC)
  ############################################################################
  origin {
    domain_name              = var.s3_bucket_regional_domain_name
    origin_id                = "s3-product-images"
    origin_access_control_id = var.s3_oac_id
  }

  ############################################################################
  # Cache Behaviour - API routes -> ALB
  ############################################################################
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "alb-dynamic"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Origin", "Accept", "Referer", "Host"]
      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  ############################################################################
  # Cache Behaviour - Product images -> S3
  ############################################################################
  ordered_cache_behavior {
    path_pattern           = "/images/*"
    target_origin_id       = "s3-product-images"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }

  ############################################################################
  # Default Cache Behaviour - all other traffic -> ALB (frontend SPA)
  ############################################################################
  default_cache_behavior {
    target_origin_id       = "alb-dynamic"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Origin", "Accept", "Host"]
      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 60
    max_ttl     = 300
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-cloudfront"
  })
}
