variable "resource_group" {
  type = object({
    name = string
    location = string
  })
}

variable "master_server" {
  type = object({
    version = string
    name = string
    sku_name = string
    storage_mb = string
    delegated_subnet_id = string
    id = string
    dns_zone_id = string
    zone = string
  })
}

variable "replica_count" {
  type = number
}

variable "replica_zone" {
  default = "2"
}

resource "azurerm_postgresql_flexible_server" "this" {
  count = var.replica_count
  name                = "${var.master_server.name}-read-replica-${count.index}"
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  version             = var.master_server.version

  storage_mb = var.master_server.storage_mb
  sku_name   = var.master_server.sku_name
  delegated_subnet_id = var.master_server.delegated_subnet_id
  auto_grow_enabled = true
  create_mode = "Replica"
  source_server_id    = var.master_server.id
  private_dns_zone_id = var.master_server.dns_zone_id
  public_network_access_enabled = false
  zone = var.replica_zone
}

resource "azurerm_postgresql_flexible_server_configuration" "require_secure_transport" {
  count = var.replica_count

  name      = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.this[count.index].id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "max_connections" {
  count = var.replica_count

  name      = "max_connections"
  server_id = azurerm_postgresql_flexible_server.this[count.index].id
  value     = 4999
}

resource "azurerm_postgresql_flexible_server_configuration" "pg_bouncer" {
  count = var.replica_count

  name      = "pgbouncer.enabled"
  server_id = azurerm_postgresql_flexible_server.this[count.index].id
  value     = true
}

resource "azurerm_postgresql_flexible_server_configuration" "default_pool_size" {
  count = var.replica_count

  name      = "pgbouncer.default_pool_size"
  server_id = azurerm_postgresql_flexible_server.this[count.index].id
  value     = 4950
}

resource "azurerm_postgresql_flexible_server_configuration" "server_idle_timeout" {
  count = var.replica_count

  name      = "pgbouncer.server_idle_timeout"
  server_id = azurerm_postgresql_flexible_server.this[count.index].id
  value     = 30
}

resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_diagnostics" {
  count = var.replica_count

  name      = "metrics.pgbouncer_diagnostics"
  server_id = azurerm_postgresql_flexible_server.this[count.index].id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "extensions" {
  count = var.replica_count

  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.this[count.index].id
  value     = "citext,pg_trgm,postgis,timescaledb,hstore,uuid-ossp,plpgsql,pg_stat_statements,vector"
}

resource "azurerm_postgresql_flexible_server_configuration" "idle_in_transaction_session_timeout" {
  count = var.replica_count

  name      = "idle_in_transaction_session_timeout"
  server_id = azurerm_postgresql_flexible_server.this[count.index].id
  value     = 3600000
}

resource "azurerm_postgresql_flexible_server_configuration" "idle_session_timeout" {
  count = var.replica_count

  name      = "idle_session_timeout"
  server_id = azurerm_postgresql_flexible_server.this[count.index].id
  value     = 3600000
}

resource "azurerm_postgresql_flexible_server_configuration" "pg_qs_parameters_capture_mode" {
  count = var.replica_count

  name      = "pg_qs.query_capture_mode"
  server_id = azurerm_postgresql_flexible_server.this[count.index].id
  value     = "TOP"
}

resource "azurerm_postgresql_flexible_server_configuration" "pgms_wait_sampling_query_capture_mode" {
  count = var.replica_count

  name      = "pgms_wait_sampling.query_capture_mode"
  server_id = azurerm_postgresql_flexible_server.this[count.index].id
  value     = "ALL"
}

resource "azurerm_postgresql_flexible_server_configuration" "track_io_timing" {
  count = var.replica_count

  name      = "track_io_timing"
  server_id = azurerm_postgresql_flexible_server.this[count.index].id
  value     = "on"
}

output "endpoints" {
  value = azurerm_postgresql_flexible_server.this.*.fqdn
}