terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "mybuck" {
  bucket = "parinaportfolio"
  force_destroy = true

  tags = {
    Name        = "MyS3Bucket"
    Environment = "Dev"
  }
}
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.mybuck.bucket

  index_document {
    suffix = "portofolio.html"
  }

  error_document {
    key = "404.html"
  }
}

resource "aws_s3_bucket_public_access_block" "allow_publick" {
  bucket = aws_s3_bucket.mybuck.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.mybuck.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_object" "all_files" {
  for_each = fileset("${path.module}/files", "*")

  bucket       = aws_s3_bucket.mybuck.bucket
  key          = each.value
  source       = "${path.module}/files/${each.value}"
  etag         = filemd5("${path.module}/files/${each.value}")

  content_type = lookup(
    {
      html = "text/html"
      jpg  = "image/jpeg"
      jpeg = "image/jpeg"
      png  = "image/png"
      pdf  = "application/pdf"
    },
    lower(trimspace(split(".", each.value)[length(split(".", each.value)) - 1])),
    "application/octet-stream"
  )
}
