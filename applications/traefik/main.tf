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

provider "docker" {
  alias = "remote"

  host = "tcp://${var.docker.host}:2376"
  cert_material = var.docker.cert
  ca_material = var.docker.ca_cert
  key_material = var.docker.key
}

resource "docker_service" "this" {
  provider = docker.remote

  name = "proxy"
  mode {
    global = true
  }
  task_spec {
    container_spec {
      image = docker_image.this.name
      mounts {
        source = "/var/run/docker.sock"
        target = "/var/run/docker.sock"
        type   = "bind"
        read_only = true
      }
    }
    placement {
      constraints = [
        "node.role==manager"
      ]
      prefs = [
        "spread=node.role.manager",
      ]
      max_replicas = 1
    }
  }
  endpoint_spec {
    ports {
      name = "web"
      protocol = "tcp"
      target_port = 80
      published_port = 80
      publish_mode = "ingress"
    }
  }
}