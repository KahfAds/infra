terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {
  alias = "remote"

  host          = "tcp://${var.docker.host}:2376"
  cert_material = var.docker.cert
  ca_material   = var.docker.ca_cert
  key_material  = var.docker.key
}

# resource "docker_service" "this" {
#   provider = docker.remote
#
#   labels {
#     label = "traefik.enable"
#     value = "true"
#   }
#
#   labels {
#     label = "traefik.http.services.revive-adserver-backend.loadbalancer.server.port"
#     value = "80"
#   }
#
#   name = "revive-adserver-backend"
#   mode {
#     replicated {
#       replicas = 2
#     }
#   }
#
#   task_spec {
#     placement {
#       constraints = [
#         "node.role==worker",
#       ]
#       prefs = [
#         "spread=node.role.worker",
#       ]
#     }
#     container_spec {
#       image = "reviveadserver.azurecr.io/revive-adserver-production/backend:latest"
#       command = [
#         "/bin/bash",
#         "-c",
#         "/usr/local/bin/entrypoint.sh && /usr/bin/supervisord -n"
#       ]
#       args = [
#         "--privileged=true",
#         "--cap_add=SYS_ADMIN",
#         "--devices=/dev/fuse",
#         "--security_opt=apparmor:unconfined"
#       ]
#       env = {
#         DB_HOST = var.database.host
#         DB_PORT = 5432
#         DB_NAME = var.database.name
#         DB_USERNAME = var.database.username
#         DB_PASSWORD = var.database.password
#         AZURE_STORAGE_ACCOUNT: azurerm_storage_account.this.name
#       }
#       mounts {
#         source    = "/var/run/docker.sock"
#         target    = "/var/run/docker.sock"
#         type      = "bind"
#         read_only = true
#       }
#       secrets {
#         file_name = "azure_storage_access_key"
#         secret_id = docker_secret.azure_storage_access_key.id
#         secret_name = docker_secret.azure_storage_access_key.name
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
#
# #   update_config {
# #     parallelism     = 1
# #     delay           = "10s"
# #     failure_action  = "pause"
# #     monitor         = "30s"
# #     max_failure_ratio = 0.3
# #   }
# }

resource "docker_secret" "azure_storage_access_key" {
  data = base64encode(azurerm_storage_account.this.primary_access_key)
  name = "azure_storage_access_key"
}
