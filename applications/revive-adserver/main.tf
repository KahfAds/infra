locals {
  location = "southeastasia"

  stack = base64encode(templatefile("${path.module}/docker-compose.yml", {
    DB_HOST = azurerm_private_dns_zone_virtual_network_link.database.name
    DB_PORT = 5432
    DB_NAME = azurerm_postgresql_flexible_server_database.revive_ad_server.name
    DB_USERNAME = local.database_user
    DB_PASSWORD = random_password.database.result
    ENV = "production"
    AZURE_STORAGE_ACCOUNT = azurerm_storage_account.this.name
    AZURE_STORAGE_ACCESS_KEY = azurerm_storage_account.this.primary_access_key
  }))
}

resource "azurerm_resource_group" "this" {
  location = local.location
  name     = "ad-server-01"
}

