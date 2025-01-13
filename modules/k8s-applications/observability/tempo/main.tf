variable "namespace" {
  default = "observability"
}

resource "helm_release" "this" {
  chart = "tempo"
  name  = "tempo"
  repository = "https://grafana.github.io/helm-charts"
  version = "1.16.0"
  create_namespace = true
  namespace = var.namespace
}

output "endpoint" {
  value = "http://tempo.${var.namespace}.svc.cluster.local:3100"
}