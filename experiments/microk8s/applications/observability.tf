module "prometheus" {
  source = "../../../modules/k8s-applications/observability/kube-prom-stack"
  kube_controller_manager_endpoints = local.manager_ips
  kube_scheduler_endpoints = local.manager_ips
  loki_endpoint = module.loki.backend_endpoint
  tempo_endpoint = module.tempo.endpoint
}

module "loki" {
  source = "../../../modules/k8s-applications/observability/loki"
  alert_manager_endpoint = module.prometheus.alert_manager_endpoint
}

module "promtail" {
  source = "../../../modules/k8s-applications/observability/promtail"
  push_endpoint = "${module.loki.backend_endpoint}/loki/api/v1/push"
}

module "tempo" {
  source = "../../../modules/k8s-applications/observability/tempo"
}