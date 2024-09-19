module "manager" {
  source = "./manager"

  default_docker_network = var.default_docker_network
  deployed_stacks = var.deployed_stacks
  location = var.location
  name_prefix = "${var.name_prefix}-docker-swarm-manager"
  network = var.network
  private_ip_address = var.manager_0_private_ip
  accessible_registries = var.accessible_registries
  resource_group_name = var.resource_group_name
  roles = var.roles
  subnet = var.subnet
  docker_secrets = var.docker_secrets
}

module "worker" {
  depends_on = [module.manager]
  source = "./worker"
  location = var.location
  name_prefix = "${var.name_prefix}-docker-swarm-worker"
  network = var.network
  accessible_registries = var.accessible_registries
  resource_group_name = var.resource_group_name
  roles = var.roles
  subnet = var.subnet
  join_command = module.manager.worker_join_command
}