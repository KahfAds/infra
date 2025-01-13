variable "push_endpoint" {}

resource "helm_release" "this" {
  chart = "promtail"
  name  = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  version = "6.16.6"
  values = [
    templatefile("${path.module}/values.yaml",{
     PUSH_ENDPOINT = var.push_endpoint
    })
  ]
}