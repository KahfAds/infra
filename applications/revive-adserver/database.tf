locals {
  database_user = "psqladmin"
}

resource "random_password" "database" {
  length = 10
}

resource "azurerm_subnet" "database" {
  name                 = "database-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = module.core_network.vnet_name
  address_prefixes = ["10.0.4.0/24"]
  service_endpoints = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_private_dns_zone" "database" {
  name                = "revive-adserver.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "database" {
  name                  = "revive-adserver.postgres.database.azure.com"
  private_dns_zone_name = azurerm_private_dns_zone.database.name
  virtual_network_id    = module.core_network.vnet_id
  resource_group_name   = azurerm_resource_group.this.name
  depends_on = [azurerm_subnet.database]
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                = "revive-adserver"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  administrator_login    = local.database_user
  administrator_password = random_password.database.result

  sku_name   = "GP_Standard_D2s_v3"
  version    = "16"
  storage_mb = 65536

  backup_retention_days        = 30
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  public_network_access_enabled = false

  high_availability {
    mode                      = "ZoneRedundant"
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.database,
    azurerm_private_dns_zone_virtual_network_link.database
  ]

  lifecycle {
    ignore_changes = [
      zone,
      high_availability.0.standby_availability_zone
    ]
  }
}

resource "azurerm_postgresql_flexible_server_database" "revive_ad_server" {
  name      = "revive-adserver"
  server_id = azurerm_postgresql_flexible_server.this.id
  collation = "en_US.utf8"
  charset   = "utf8"

  lifecycle {
    prevent_destroy = true
  }
}