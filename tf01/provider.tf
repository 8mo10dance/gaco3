terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region              = "ap-northeast-1"
  profile             = "default"
  allowed_account_ids = ["347408264688"]
}
