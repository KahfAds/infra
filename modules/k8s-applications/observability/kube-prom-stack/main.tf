variable "kube_controller_manager_endpoints" {
  type = list(string)
}

variable "kube_scheduler_endpoints" {
  type = list(string)
}

variable "loki_endpoint" {}

variable "tempo_endpoint" {}

variable "namespace" {
  default = "observability"
}

resource "helm_release" "this" {
  chart = "kube-prometheus-stack"
  name  = "kube-prom-stack"
  version = "67.10.0"
  namespace = var.namespace

  repository = "https://prometheus-community.github.io/helm-charts"

  values = [templatefile("${path.module}/values.yaml", {
    manager_endpoints = var.kube_controller_manager_endpoints
    scheduler_endpoints = var.kube_scheduler_endpoints
    loki_endpoint = var.loki_endpoint
    tempo_endpoint = var.tempo_endpoint
  })]
}

output "alert_manager_endpoint" {
  value = "http://alertmanager-operated.${var.namespace}.svc.cluster.local:9093"
}