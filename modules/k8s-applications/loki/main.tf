terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.14.0"
    }
  }
}
resource "helm_release" "loki" {
  chart = "loki"
  name  = "loki"
  repository = "https://grafana.github.io/helm-charts"
  version = "6.24.0"

  values = [file("${path.module}/config.yaml")]
}