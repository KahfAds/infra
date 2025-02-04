module "blob" {
  source = "../../modules/azure/storages/blob/v1"
  containers = {
    backups = "private"
    ethicaladserver = "blob"
  }
  name   = "${local.name_prefix}${local.env}"
  resource_group = {
    name = azurerm_resource_group.this.name
    location = azurerm_resource_group.this.location
  }
}

module "nfs" {
  source = "../../modules/azure/storages/nfs/v1"
  name_prefix = "${local.name_prefix}nfs${local.env}"
  resource_group = {
    name = azurerm_resource_group.this.name
    location = azurerm_resource_group.this.location
  }
  subnets = local.subnet_objects
  vnet_id = module.core_network.vnet_id
}