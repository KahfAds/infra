resource "azurerm_private_dns_zone" "storage_blob_dns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_storage_account" "this" {
  depends_on = [module.core_network]

  account_replication_type      = "LRS"
  account_tier                  = "Standard"
  location                      = azurerm_resource_group.this.location
  name                          = "kahfads${local.env}"
  resource_group_name           = azurerm_resource_group.this.name
  account_kind                  = "StorageV2"
  public_network_access_enabled = true
  https_traffic_only_enabled    = false

  static_website {
    index_document = "index.html"
    error_404_document = "404.html"
  }
}

resource "azurerm_storage_container" "this" {
  name                  = "ethicaladserver"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "blob"
}

resource "azurerm_storage_container" "backup" {
  name                  = "backups"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}