variable "resource_group" {
  type = object({
    name = string
    location = string
  })
}

variable "name" {}

resource "azurerm_private_dns_zone" "this" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group.name
}

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

output "account" {
  value = azurerm_storage_account.this.name
}

output "primary_access_key" {
  value = azurerm_storage_account.this.primary_access_key
}

output "primary_blob_host" {
  value = azurerm_storage_account.this.primary_blob_host
}