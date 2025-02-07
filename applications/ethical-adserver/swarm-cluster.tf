locals {
  manager_0_private_ip = cidrhost(local.subnets[0].prefix, 10)
}

module "swarm_cluster" {
  depends_on = [module.core_network.vnet_id]
  source = "../../modules/docker-swarm/setup/azure/v2"

  accessible_registries = [azurerm_container_registry.this.name]
  location               = local.location
  manager_0_private_ip   = local.manager_0_private_ip
  name_prefix            = "adserver"
  resource_group_name    = azurerm_resource_group.this.name
  subnet = {
    id     = module.core_network.vnet_subnets[0]
    prefix = local.subnets[0].prefix
  }
  network = {
    prefix = module.core_network.vnet_address_space[0]
  }
  worker_scale = {
    min = 0
    max = 0
    desired = 0
  }
}

provider "docker" {
  alias = "swarm"
  host = "tcp://${module.swarm_cluster.docker.host}:2376"
  cert_material = module.swarm_cluster.docker.cert
  ca_material = module.swarm_cluster.docker.ca_cert
  key_material = module.swarm_cluster.docker.key
}