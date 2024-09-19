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
  subnet_service_endpoints = {
    for subnet in local.subnets : subnet.name => ["Microsoft.Storage"]
  }
}