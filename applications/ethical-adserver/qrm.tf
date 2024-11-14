module "qrm" {
  source = "./stacks/qrm"
  docker_config_name = docker_config.this[local.docker_configs.qrm_app.name].name
  storage_account_name = module.nfs.account
  nfs_endpoint = module.nfs.endpoint
}