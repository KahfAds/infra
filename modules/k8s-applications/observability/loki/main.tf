variable "namespace" {
  default = "observability"
}

variable "alert_manager_endpoint" {}

resource "helm_release" "this" {
  chart = "loki"
  name  = "loki"
  repository = "https://grafana.github.io/helm-charts"
  version = "6.24.0"
  create_namespace = true
  namespace = var.namespace

  values = [templatefile("${path.module}/values.yaml", {
    ALERT_MANAGER_ENDPOINT = var.alert_manager_endpoint
  })]
}