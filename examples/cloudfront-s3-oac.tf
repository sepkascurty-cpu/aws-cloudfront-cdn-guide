# CloudFront + private S3 origin with Origin Access Control (OAC).
# The bucket stays private: only this CloudFront distribution can read it.
# Usage: terraform init && terraform apply

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1" # Singapore — closest AWS region to most Indonesian users
}

resource "random_pet" "suffix" {
  length = 2
}

# --- Private origin bucket: NO public access, NO website endpoint ---
resource "aws_s3_bucket" "site" {
  bucket = "cloudfront-site-${random_pet.suffix.id}"
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- Origin Access Control (replaces legacy OAI) ---
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "oac-${random_pet.suffix.id}"
  description                       = "OAC for private S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# --- Distribution ---
resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  comment             = "Static site behind CloudFront"
  default_root_object = "index.html"
  price_class         = "PriceClass_100" # US + EU only; switch to PriceClass_All for global users

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    # Managed policies: optimized caching, no query strings/cookies in cache key.
    cache_policy_id          = "658327ea-f89d-4fab-a63-7e88639e58f6" # CachingOptimized
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# --- Bucket policy: ONLY this distribution may read the bucket ---
data "aws_iam_policy_document" "site" {
  statement {
    sid    = "AllowCloudFrontOnly"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site.json
}

output "bucket_name" {
  value = aws_s3_bucket.site.id
}

output "distribution_domain" {
  value = aws_cloudfront_distribution.site.domain_name
}
