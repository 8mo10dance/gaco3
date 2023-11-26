terraform {
  backend "local" {}
}

provider "aws" {
  region     = "ap-northeast-1"
  access_key = "test"
  secret_key = "test"

  s3_use_path_style = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3 = "http://localstack:4566"
  }
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "microposts"

  cors_rule {
    allowed_methods = ["PUT"]
    allowed_origins = ["*"]
  }
}
