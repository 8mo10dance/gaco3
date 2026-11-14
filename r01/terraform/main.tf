terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region                      = "ap-northeast-1"
  access_key                  = "dummy"
  secret_key                  = "dummy"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3 = "http://floci:4566"
  }
}

resource "aws_s3_bucket" "microposts" {
  bucket = "microposts"
}

# CarrierWave が public-read ACL を付けて保存する画像をブラウザから参照する。
resource "aws_s3_bucket_ownership_controls" "microposts" {
  bucket = aws_s3_bucket.microposts.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "microposts" {
  bucket = aws_s3_bucket.microposts.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "microposts" {
  bucket = aws_s3_bucket.microposts.id

  cors_rule {
    allowed_methods = ["PUT"]
    allowed_origins = ["*"]
  }
}
