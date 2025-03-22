locals {
  manager_0_private_ip = cidrhost(local.subnets[0].prefix, 10)
}

module "swarm_cluster" {
  depends_on = [module.core_network.vnet_id]
  source = "../../modules/docker-swarm/setup/azure/v2"

  accessible_registries = [azurerm_container_registry.this.name]
  location             = local.location
  manager_0_private_ip = local.manager_0_private_ip
  name_prefix          = "${local.name_prefix}-${var.env}"
  resource_group_name  = azurerm_resource_group.this.name
  subnet = {
    id     = module.core_network.vnet_subnets[0]
    prefix = local.subnets[0].prefix
  }
  network = {
    prefix = module.core_network.vnet_address_space[0]
  }
  worker_scale = {
    min     = 8
    max     = 8
    desired = 8
  }
  manager_replica       = 2
  create_docker_context = true
}