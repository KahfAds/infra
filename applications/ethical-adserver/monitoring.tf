module "monitoring" {
  source = "./stacks/monitoring"
  storage_account_name = module.nfs.account
  nfs_endpoint = module.nfs.endpoint
  prometheus_config_name = docker_config.this[local.docker_configs.prometheus.name].name
}