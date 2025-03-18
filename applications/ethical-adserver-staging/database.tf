locals {
  database_user = "psqladmin"
}

resource "random_password" "database" {
  length = 16
  special = false
}

resource "azurerm_subnet" "database" {
  name                 = "database-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = module.core_network.vnet_name
  address_prefixes     = ["172.16.4.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
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
  name                = "${local.name_prefix}${var.env}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "database" {
  name                  = "database"
  private_dns_zone_name = azurerm_private_dns_zone.database.name
  virtual_network_id    = module.core_network.vnet_id
  resource_group_name   = azurerm_resource_group.this.name
  depends_on            = [azurerm_subnet.database]
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                = "${local.name_prefix}-${var.env}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  delegated_subnet_id = azurerm_subnet.database.id
  private_dns_zone_id = azurerm_private_dns_zone.database.id

  administrator_login    = local.database_user
  administrator_password = random_password.database.result

  sku_name   = "B_Standard_B4ms"
  version    = "16"
  storage_mb = 65536

  backup_retention_days        = 30
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  public_network_access_enabled = false

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.database
  ]

  lifecycle {
    ignore_changes = [
      zone,
      high_availability.0.standby_availability_zone
    ]
    prevent_destroy = true
  }
}

module "master_server_parameters" {
  source = "../../modules/azure/postgres/server-parameters"
  server = {
    id = azurerm_postgresql_flexible_server.this.id
    sku_name = azurerm_postgresql_flexible_server.this.sku_name
  }
}

resource "azurerm_postgresql_flexible_server_database" "backend" {
  name      = "ethicaladserver"
  server_id = azurerm_postgresql_flexible_server.this.id
  collation = "en_US.utf8"
  charset   = "utf8"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_postgresql_flexible_server_database" "metabase" {
  name      = "metabase_app_db"
  server_id = azurerm_postgresql_flexible_server.this.id
  collation = "en_US.utf8"
  charset   = "utf8"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_postgresql_flexible_server_database" "qr_code_management" {
  name      = "qr-code-management"
  server_id = azurerm_postgresql_flexible_server.this.id
  collation = "en_US.utf8"
  charset   = "utf8"

  lifecycle {
    prevent_destroy = true
  }
}