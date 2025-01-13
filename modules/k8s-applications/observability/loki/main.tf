variable "namespace" {
  default = "observability"
}

resource "helm_release" "loki" {
  chart = "loki"
  name  = "loki"
  repository = "https://grafana.github.io/helm-charts"
  version = "6.24.0"
  create_namespace = true
  namespace = var.namespace

  values = [file("${path.module}/values.yaml")]
}