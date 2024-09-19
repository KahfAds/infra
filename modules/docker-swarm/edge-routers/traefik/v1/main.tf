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

provider "docker" {
  alias = "remote"

  host          = "tcp://${var.docker.host}:2376"
  cert_material = var.docker.cert
  ca_material   = var.docker.ca_cert
  key_material  = var.docker.key
}

resource "random_password" "basic_auth" {
  length = 12
  special = true
  override_special = "_%@"
}

# resource "docker_service" "this" {
#   provider = docker.remote
#
#   name = "proxy"
#   mode {
#     global = true
#   }
#
#   labels {
#     label = "traefik.enable"
#     value = "true"
#   }
#
#   labels {
#     label = "traefik.http.services.proxy.loadbalancer.server.port"
#     value = "9999"
#   }
#
#   labels {
#     label = "traefik.http.routers.dashboard.entrypoints"
#     value = "traefik"
#   }
#
#   labels { # if don't add this, then implicitly traefik adds rule "Host(`proxy`)" !!!
#     label = "traefik.http.routers.dashboard.rule"
#     value = "(PathPrefix(`/api`) || PathPrefix(`/dashboard`))"
#   }
#
#   labels {
#     label = "traefik.http.routers.dashboard.service"
#     value = "api@internal"
#   }
# #
#   labels {
#     label = "traefik.http.routers.dashboard.middlewares"
#     value = "auth"
#   }
# #
#   labels {
#     label = "traefik.http.middlewares.auth.basicauth.users"
#     value = "admin:${random_password.basic_auth.bcrypt_hash}"
#   }
#
#   task_spec {
#     placement {
#       constraints = [
#         "node.role==manager",
#       ]
#       prefs = [
#         "spread=node.role.manager",
#       ]
#     }
#     container_spec {
#       image = "traefik:v3.1.2"
#       args = [
#         "--log.level=DEBUG",
#         "--accesslog=true",
#         "--api=true",
#         "--api.dashboard=true",
# #         "--api.insecure=true",
#         "--entrypoints.web.address=:80",
#         "--entrypoints.websecure.address=:443",
#         "--providers.swarm=true",
#         "--providers.swarm.exposedByDefault=false",
#         "--providers.docker.endpoint=unix:///var/run/docker.sock",
#         "--entryPoints.ping.address=:8082",
#         "--entryPoints.traefik.address=:8080",
#         "--ping.entryPoint=ping"
#       ]
#       mounts {
#         source    = "/var/run/docker.sock"
#         target    = "/var/run/docker.sock"
#         type      = "bind"
#         read_only = true
#       }
#     }
#   }
#
#   endpoint_spec {
#     ports {
#       name           = "web"
#       protocol       = "tcp"
#       target_port    = 80
#       published_port = 80
#       publish_mode   = "ingress"
#     }
#     ports {
#       name           = "websecure"
#       protocol       = "tcp"
#       target_port    = 443
#       published_port = 443
#       publish_mode   = "ingress"
#     }
#     ports {
#       name           = "api"
#       protocol       = "tcp"
#       target_port    = 8080
#       published_port = 8080
#       publish_mode   = "ingress"
#     }
#     ports {
#       name           = "ping"
#       protocol       = "tcp"
#       target_port    = 8082
#       published_port = 8082
#       publish_mode   = "ingress"
#     }
#   }
# }

resource "docker_network" "this" {
  provider = docker.remote
  name = "public"
  driver = "overlay"
}
