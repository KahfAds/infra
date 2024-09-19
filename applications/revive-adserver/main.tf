locals {
  location = "southeastasia"

  volumes = {
    admin-plugins : []
    images : []
    plugins : []
    var : ["cache/dummy.txt", "plugins/DataObjects/dummy.txt", "plugins/recover/dummy.txt"]
  }

  stack = base64encode(templatefile("docker-compose.yml.tpl", {
    DB_HOST                    = azurerm_private_dns_zone_virtual_network_link.database.name
    DB_PORT                    = 5432
    DB_NAME                    = azurerm_postgresql_flexible_server_database.revive_ad_server.name
    DB_USERNAME                = local.database_user
    DB_PASSWORD                = random_password.database.result
    ENV                        = "production"
    AZURE_STORAGE_ACCOUNT_HOST = "${azurerm_storage_account.this.name}.${azurerm_private_dns_zone.storage_blob_dns.name}"
    AZURE_STORAGE_ACCOUNT      = azurerm_storage_account.this.name
    volumes = keys(local.volumes)
  }))
}

resource "azurerm_resource_group" "this" {
  location = local.location
  name     = "ad-server-01"
}

