variable "kube_controller_manager_endpoints" {
  type = list(string)
}

variable "kube_scheduler_endpoints" {
  type = list(string)
}

resource "helm_release" "this" {
  chart = "kube-prometheus-stack"
  name  = "kube-prom-stack"
  version = "67.10.0"
  repository = "https://prometheus-community.github.io/helm-charts"

  values = [templatefile("${path.module}/values.yaml", {
    manager_endpoints = var.kube_controller_manager_endpoints
    scheduler_endpoints = var.kube_scheduler_endpoints
  })]
}