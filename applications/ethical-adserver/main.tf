locals {
  location = "southeastasia"
}

resource "azurerm_resource_group" "this" {
  location = local.location
  name     = "kahf-ads-${local.env}"
}
