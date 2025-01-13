variable "push_endpoint" {}

variable "namespace" {
  default = "observability"
}

resource "helm_release" "this" {
  chart = "promtail"
  name  = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  version = "6.16.6"
  create_namespace = true
  namespace = var.namespace
  values = [
    templatefile("${path.module}/values.yaml",{
     PUSH_ENDPOINT = var.push_endpoint
    })
  ]
}