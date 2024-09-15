terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {
  host = "unix://${pathexpand("~/.docker/run/docker.sock")}"

  registry_auth {
    address  = var.registry.address
    username = var.registry.username
    password = var.registry.password
  }
}

resource "docker_registry_image" "this" {
  name          = docker_image.this.name
  keep_remotely = true
  triggers = {
    dockerfile = sha1(file("${path.module}/Dockerfile"))
  }
}

resource "docker_image" "this" {
  name = "${var.registry.address}/infrastructure/proxy:1.0"
  build {
    context  = "${path.module}/"
    no_cache = true
  }
  platform = "linux/amd64"
  triggers = {
    dockerfile = sha1(file("${path.module}/Dockerfile"))
  }
}

provider "docker" {
  alias = "remote"

  host          = "tcp://${var.docker.host}:2376"
  cert_material = var.docker.cert
  ca_material   = var.docker.ca_cert
  key_material  = var.docker.key
}

resource "docker_service" "traefik" {
  provider = docker.remote

  name = "traefik"
  mode {
    global = true
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.services.traefik.loadbalancer.server.port"
    value = "8080"
  }

  task_spec {
    container_spec {
      image = "traefik:v3.1.2"
      args = [
        "--log.level=DEBUG",
        "--accesslog=true",
        "--api=true",
        "--api.dashboard=true",
        "--api.insecure=true",
        "--entrypoints.web.address=:80",
        "--providers.swarm.endpoint=tcp://127.0.0.1:2377",
        "--providers.docker.endpoint=unix:///var/run/docker.sock",
        "--entryPoints.ping.address=:8082",
        "--ping.entryPoint=ping"
      ]
      mounts {
        source    = "/var/run/docker.sock"
        target    = "/var/run/docker.sock"
        type      = "bind"
        read_only = true
      }
    }
  }

  endpoint_spec {
    ports {
      name           = "web"
      protocol       = "tcp"
      target_port    = 80
      published_port = 80
      publish_mode   = "ingress"
    }
    ports {
      name           = "websecure"
      protocol       = "tcp"
      target_port    = 443
      published_port = 443
      publish_mode   = "ingress"
    }
    ports {
      name           = "api"
      protocol       = "tcp"
      target_port    = 8080
      published_port = 8080
      publish_mode   = "ingress"
    }
    ports {
      name           = "ping"
      protocol       = "tcp"
      target_port    = 8082
      published_port = 8082
      publish_mode   = "ingress"
    }
  }
}
