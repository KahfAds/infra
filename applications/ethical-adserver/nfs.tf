module "nfs" {
  source = "../../modules/azure/nfs/v1"
  name_prefix = "kahfadsnfs${local.env}"
  resource_group = {
    name = azurerm_resource_group.this.name
    location = azurerm_resource_group.this.location
  }
  subnets = local.subnet_objects
  vnet_id = module.core_network.vnet_id
}