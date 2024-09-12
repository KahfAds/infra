locals {
  location = "southeastasia"
}

resource "azurerm_resource_group" "this" {
  location = local.location
  name     = "ad-server-01"
}

