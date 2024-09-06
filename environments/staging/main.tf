resource "azurerm_resource_group" "this" {
  location = ""
  name     = ""
}

module "core_network" {
  source              = "Azure/network/azurerm"
  resource_group_name = azurerm_resource_group.this.name
  address_spaces      = ["10.0.0.0/16"]
  subnet_prefixes     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  subnet_names        = ["subnet1", "subnet2", "subnet3"]

  use_for_each = true
  tags = {
    environment = terraform.workspace
  }
  depends_on = [azurerm_resource_group.this]
}