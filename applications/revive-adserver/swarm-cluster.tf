locals {
  manager_0_private_ip = cidrhost(local.subnets[0].prefix, 10)
}

module "swarm_cluster" {
  depends_on = [module.core_network.vnet_id]
  source = "../../modules/docker-swarm/azure/v2"

  accessible_registries = [azurerm_container_registry.revive_ad_server.name]
  location             = local.location
  manager_0_private_ip = local.manager_0_private_ip
  name_prefix          = "revive-adserver"
  resource_group_name  = azurerm_resource_group.this.name
  subnet = {
    id     = module.core_network.vnet_subnets[0]
    prefix = local.subnets[0].prefix
  }
  network = {
    prefix = module.core_network.vnet_address_space[0]
  }
  docker_secrets = {
#     DB_USERNAME = local.database_user
#     DB_PASSWORD = random_password.database.result
#     DB_HOST     = azurerm_private_dns_zone_virtual_network_link.database.name
#     DB_PORT     = 5432
#     DB_NAME     = azurerm_postgresql_flexible_server_database.revive_ad_server.name
  }
}