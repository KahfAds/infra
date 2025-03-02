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

  sku_name   = "GP_Standard_D2ds_v5"
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

module "postgres_replicas" {
  source = "../../modules/azure/postgres/replica"
  master_server = {
    version = azurerm_postgresql_flexible_server.this.version
    name = azurerm_postgresql_flexible_server.this.name
    sku_name = azurerm_postgresql_flexible_server.this.sku_name
    storage_mb = azurerm_postgresql_flexible_server.this.storage_mb
    delegated_subnet_id = azurerm_postgresql_flexible_server.this.delegated_subnet_id
    id = azurerm_postgresql_flexible_server.this.id
    dns_zone_id = azurerm_postgresql_flexible_server.this.private_dns_zone_id
    zone = azurerm_postgresql_flexible_server.this.zone
  }
  replica_count = 4
  resource_group = {
    name = azurerm_resource_group.this.name
    location = azurerm_resource_group.this.location
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

resource "azurerm_postgresql_flexible_server_configuration" "require_secure_transport" {
  name      = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "max_connections" {
  name      = "max_connections"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = 4500
}

resource "azurerm_postgresql_flexible_server_configuration" "pg_bouncer" {
  name      = "pgbouncer.enabled"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = true
}

resource "azurerm_postgresql_flexible_server_configuration" "default_pool_size" {
  name      = "pgbouncer.default_pool_size"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = 4950
}

resource "azurerm_postgresql_flexible_server_configuration" "server_idle_timeout" {
  name      = "pgbouncer.server_idle_timeout"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = 30
}

resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_diagnostics" {
  name      = "metrics.pgbouncer_diagnostics"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "extensions" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = "citext,pg_trgm,postgis,timescaledb,hstore,uuid-ossp,plpgsql,pg_stat_statements,vector"
}