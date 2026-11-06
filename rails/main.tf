terraform {
  required_version = ">= 1.5.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.6"
    }
  }
}

# Docker Desktop では DOCKER_CONTEXT=desktop-linux を指定する。
provider "docker" {}

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
