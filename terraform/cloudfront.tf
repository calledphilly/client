resource "aws_cloudfront_origin_access_identity" "core" {
  comment = "cfbuck1234.s3.us-east-1.amazonaws.com"
}

resource "aws_s3_bucket_acl" "core" {
  bucket = aws_s3_bucket.core.id
  acl = "private"
}

locals {
  s3_origin_id = aws_s3_bucket.core.id
}

resource "aws_cloudfront_origin_access_control" "core" {
  name = "core"
  description  = "Core Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}

resource "aws_cloudfront_distribution" "core" {
  origin {
    domain_name = aws_s3_bucket.core.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.core.id
    origin_id = local.s3_origin_id
  }

  enabled = true
  is_ipv6_enabled = true
  comment = "Some comment"
  default_root_object = var.document

  # logging_config {
  #   include_cookies = false
  #   bucket = aws_s3_bucket.core.id
  #   prefix = "logs/"
  # }

  # aliases = ["mysite.example.com", "yoursite.example.com"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern = "/content/immutable/*"
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl = 0
    default_ttl = 86400
    max_ttl = 31536000
    compress = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
    compress = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = var.tags

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}