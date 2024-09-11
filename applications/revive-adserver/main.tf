locals {
  location = "southeastasia"
}

resource "azurerm_resource_group" "this" {
  location = local.location
  name     = "ad-server-01"
}

locals {
  subnets = [
    {
      name = "subnet1"
      prefix = "10.0.1.0/24"
    },
    {
      name = "subnet2"
      prefix = "10.0.2.0/24"
    },
    {
      name = "subnet3"
      prefix = "10.0.3.0/24"
    }
  ]
}

module "core_network" {
  source              = "Azure/network/azurerm"
  resource_group_name = azurerm_resource_group.this.name
  address_spaces      = ["10.0.0.0/16"]
  subnet_prefixes     = local.subnets.*.prefix
  subnet_names        = local.subnets.*.name

  use_for_each = true
  tags = {
    environment = terraform.workspace
  }
  depends_on = [azurerm_resource_group.this]
}

module "swarm_cluster" {
  depends_on = [module.core_network.vnet_id]
  source              = "../../modules/docker-swarm/azure/v1"
  location            = local.location
  manager_0_private_ip = cidrhost(local.subnets[0].prefix, 10)
  name_prefix         = "revive-adserver-docker-swarm"
  resource_group_name = azurerm_resource_group.this.name
  subnet           = {
    id = module.core_network.vnet_subnets[0]
    prefix = local.subnets[0].prefix
  }
}