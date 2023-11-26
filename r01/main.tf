terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.26"
    }
    archive = {
      source = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
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
    lambda = "http://localstack:4566"
    iam = "http://localstack:4566"
  }
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "microposts"
}

resource "aws_s3_bucket_cors_configuration" "my_bucket" {
  bucket = aws_s3_bucket.my_bucket.id

  cors_rule {
    allowed_methods = ["PUT"]
    allowed_origins = ["*"]
  }
}

data "archive_file" "lambda_zip" {
  type = "zip"
  source_file = "index.py"
  output_path = "tmp/lambda.zip"
}

resource "aws_lambda_function" "my_lambda" {
  function_name = "my_lambda_function"
  role = aws_iam_role.lambda_role.arn
  handler = "index.handler"
  runtime = "python3.7"
  filename = data.archive_file.lambda_zip.output_path
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
      },
    ],
  })
}
