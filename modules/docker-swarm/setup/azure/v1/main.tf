module "manager" {
  source = "manager"
  location = var.location
  name_prefix = "${var.name_prefix}-docker-swarm-manager"
  network = var.network
  private_ip_address = var.manager_0_private_ip
  resource_group_name = var.resource_group_name
  subnet = var.subnet
  docker_secrets = var.docker_secrets
}

module "worker" {
  depends_on = [module.manager]
  source = "worker"
  location = var.location
  name_prefix = "${var.name_prefix}-docker-swarm-worker"
  network = var.network
  resource_group_name = var.resource_group_name
  subnet = var.subnet
  join_command = module.manager.worker_join_command
}