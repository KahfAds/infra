output "backend_endpoint" {
  value = "http://loki-gateway.${var.namespace}.svc.cluster.local"
}