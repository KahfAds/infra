variable "namespace" {
  default = "traefik"
}

variable "web_port" {
  type = number
  default = 30080
}

variable "websecure_port" {
  type = number
  default = 30443
}

variable "dashboard_port" {
  type = number
  default = 30880
}

variable "name" {
  default = "traefik"
}

resource "helm_release" "this" {
  chart = "traefik"
  name  = var.name
  repository = "https://traefik.github.io/charts"
  namespace = var.namespace
  create_namespace = true
  version = "33.2.0"

  values = [
    templatefile("${path.module}/values.yaml", {
      dashboard_port = var.dashboard_port
      web_port = var.web_port
      websecure_port = var.websecure_port
    })
  ]
}

output "class_name" {
  value = var.name
}
