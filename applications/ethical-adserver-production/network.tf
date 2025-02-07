locals {
  subnets = [
    {
      name = "subnet1"
      prefix = "172.16.1.0/24"
    },
    {
      name = "subnet2"
      prefix = "172.16.2.0/24"
    },
    {
      name = "subnet3"
      prefix = "172.16.3.0/24"
    }
  ]

  subnet_objects = [ for idx, subnet in local.subnets:
    {
      id = module.core_network.vnet_subnets[idx]
      name = subnet.name
    }
  ]
}

module "core_network" {
  source              = "Azure/network/azurerm"
  resource_group_name = azurerm_resource_group.this.name
  address_spaces      = ["172.16.0.0/12"]
  subnet_prefixes     = local.subnets.*.prefix
  subnet_names        = local.subnets.*.name

  use_for_each = true
  tags = {
    environment = var.env
  }
  depends_on = [azurerm_resource_group.this]
  subnet_service_endpoints = {
    for subnet in local.subnets : subnet.name => ["Microsoft.Storage"]
  }
}