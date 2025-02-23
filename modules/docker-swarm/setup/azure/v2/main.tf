module "manager" {
  source = "./manager"

  location = var.location
  name_prefix = "${var.name_prefix}-docker-swarm-manager"
  network = var.network
  private_ip_address = var.manager_0_private_ip
  accessible_registries = var.accessible_registries
  resource_group_name = var.resource_group_name
  roles = var.roles
  subnet = var.subnet
  docker_secrets = var.docker_secrets
  replica = var.manager_replica
  create_docker_context = var.create_docker_context
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
  scale = var.worker_scale
}