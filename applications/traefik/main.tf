terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {
  host = "unix://${pathexpand("~/.docker/run/docker.sock")}"

  registry_auth {
    address = var.registry.address
    username = var.registry.username
    password = var.registry.password
  }
}

resource "docker_registry_image" "this" {
  name = docker_image.this.name
  keep_remotely = true
  triggers = {
    dockerfile = sha1(file("${path.module}/Dockerfile"))
  }
}

resource "docker_image" "this" {
  name = "${var.registry.address}/infrastructure/proxy:1.0"
  build {
    context = "${path.module}/"
    no_cache = true
  }
  platform = "linux/amd64"
  triggers = {
    dockerfile = sha1(file("${path.module}/Dockerfile"))
  }
}