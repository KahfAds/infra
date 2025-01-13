output "grafana_endpoint" {
  value = "http://loki-gateway.${var.namespace}.svc.cluster.local"
}

output "push_endpoint" {
  value = "http://loki-gateway.${var.namespace}.svc.cluster.local/loki/api/v1/push"
}