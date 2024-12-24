# AWS S3 bucket resource

resource "aws_s3_bucket" "demo-bucket" {
  bucket = var.my_bucket_name # Name of the S3 bucket
}


# AWS S3 bucket Ownership Control
resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.demo-bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}


# AWS S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.demo-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


# AWS S3 Bucket ACL Resource
resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example,
  ]

  bucket = aws_s3_bucket.demo-bucket.id
  acl    = "public-read"
}


# AWS S3 Bucket Policy
resource "aws_s3_bucket_policy" "host_bucket_policy" {
  bucket =  aws_s3_bucket.demo-bucket.id # ID of the S3 bucket

  # Policy JSON for allowing public read access
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:GetObject",
        "Resource": "arn:aws:s3:::${var.my_bucket_name}/*"
      }
    ]
  })
}


# Template File
module "template_files" {
    source = "hashicorp/dir/template"

    base_dir = "${path.module}/website"
}

# https://registry.terraform.io/modules/hashicorp/dir/template/latest

# Website Configuration
resource "aws_s3_bucket_website_configuration" "web-config" {
  bucket =    aws_s3_bucket.demo-bucket.id  # ID of the S3 bucket

  # Configuration for the index document
  index_document {
    suffix = "index.html"
  }
}


# AWS S3 object resource for hosting bucket files
resource "aws_s3_object" "Bucket_files" {
  bucket =  aws_s3_bucket.demo-bucket.id  # ID of the S3 bucket

  for_each     = module.template_files.files
  key          = each.key
  content_type = each.value.content_type

  source  = each.value.source_path
  content = each.value.content

  # ETag of the S3 object
  etag = each.value.digests.md5
}

# AWS CloudFront Distribution
resource "aws_cloudfront_distribution" "phw_cdn" {
  origin {
    domain_name = aws_s3_bucket.demo-bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.demo-bucket.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for S3 bucket hosting website"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.demo-bucket.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
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

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for S3 bucket access"
}

# Update S3 Bucket Policy to Allow CloudFront Access
resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket = aws_s3_bucket.demo-bucket.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": aws_cloudfront_origin_access_identity.oai.iam_arn
        },
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::${aws_s3_bucket.demo-bucket.id}/*"
      }
    ]
  })
}

