module "swarm_cluster" {
  depends_on = [module.core_network.vnet_id]
  source              = "../../modules/docker-swarm/azure/v1"
  location            = local.location
  manager_0_private_ip = cidrhost(local.subnets[0].prefix, 10)
  name_prefix         = "revive-adserver"
  resource_group_name = azurerm_resource_group.this.name
  subnet           = {
    id = module.core_network.vnet_subnets[0]
    prefix = local.subnets[0].prefix
  }
  network = {
    prefix = module.core_network.vnet_address_space[0]
  }
}