variable "name_prefix" {}

variable "address_space" {
  type = list(string)
  default = ["10.0.0.0/16"]
}

variable "location" {}

variable "resource_group_name" {}

resource "azurerm_virtual_network" "this" {
  name                = "${var.name_prefix}-network"
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "internal" {
  name                 = "${var.name_prefix}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.1.0/24"]
}