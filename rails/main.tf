terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.6"
    }
  }
}

# Docker Desktop では DOCKER_CONTEXT=desktop-linux を指定する。
provider "docker" {}

provider "aws" {
  region                      = "ap-northeast-1"
  access_key                  = "dummy"
  secret_key                  = "dummy"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3        = "http://localhost:4566"
    s3control = "http://localhost:4566"
    sts       = "http://localhost:4566"
  }
}

resource "docker_network" "rails" {
  name = "rails-terraform"
}

resource "docker_image" "rails" {
  name         = "myapp:1.0.1"
  keep_locally = true

  build {
    context = abspath(path.module)
  }

  triggers = {
    dockerfile = filesha256("${path.module}/Dockerfile")
    gemfile    = filesha256("${path.module}/Gemfile")
    lockfile   = filesha256("${path.module}/Gemfile.lock")
  }
}

resource "docker_image" "floci" {
  name         = "floci/floci:latest"
  keep_locally = true
}

resource "docker_container" "floci" {
  name  = "rails-floci"
  image = docker_image.floci.image_id

  ports {
    internal = 4566
    external = 4566
  }

  networks_advanced {
    name    = docker_network.rails.name
    aliases = ["floci", "localhost.floci.io"]
  }
}

resource "docker_container" "rails" {
  name       = "rails-app"
  image      = docker_image.rails.image_id
  tty        = true
  stdin_open = true

  volumes {
    host_path      = abspath(path.module)
    container_path = "/rails"
  }

  ports {
    internal = 3000
    external = 3000
  }

  networks_advanced {
    name    = docker_network.rails.name
    aliases = ["rails"]
  }

  depends_on = [docker_container.floci]
}

resource "aws_s3_bucket" "avatars" {
  bucket = "mybucket"

  depends_on = [docker_container.floci]
}

resource "aws_s3_bucket_ownership_controls" "avatars" {
  bucket = aws_s3_bucket.avatars.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "terraform_data" "db_prepare" {
  triggers_replace = {
    container = docker_container.rails.id
    database  = filesha256("${path.module}/config/database.yml")
    migrations = sha256(jsonencode({
      for file in fileset(path.module, "db/migrate/*.rb") :
      file => filesha256("${path.module}/${file}")
    }))
  }

  provisioner "local-exec" {
    command = "docker exec -e RAILS_ENV=development -e DISABLE_SPRING=1 ${docker_container.rails.name} bundle exec rails db:prepare"
  }
}
