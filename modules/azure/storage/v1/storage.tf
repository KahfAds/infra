variable "resource_group" {
  type = object({
    name = string
    location = string
  })
}

variable "name" {}

resource "azurerm_storage_account" "this" {
  account_replication_type      = "LRS"
  account_tier                  = "Standard"
  location                      = var.resource_group.location
  name                          = var.name
  resource_group_name           = var.resource_group.name
  account_kind                  = "StorageV2"
  public_network_access_enabled = true
  https_traffic_only_enabled    = false

  static_website {
    index_document = "index.html"
    error_404_document = "404.html"
  }
}

variable "containers" {
  type = map(string) # { name => access_type }
}

resource "azurerm_storage_container" "this" {
  for_each = var.containers
  name                  = each.key
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = each.value
}