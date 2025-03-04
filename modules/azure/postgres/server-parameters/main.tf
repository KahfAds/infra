variable "server" {
  type = object({
    id = string
    sku_name = string
  })
}

locals {
  pgbouncer_available = !startswith(var.server.sku_name, "B_")
}

variable "enable_pgbouncer" {
  type = bool
  default = true
}

resource "azurerm_postgresql_flexible_server_configuration" "require_secure_transport" {
  name      = "require_secure_transport"
  server_id = var.server.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "max_connections" {
  name      = "max_connections"
  server_id = var.server.id
  value     = 4500
}

resource "azurerm_postgresql_flexible_server_configuration" "pg_bouncer" {
  count = local.pgbouncer_available ? 1 : 0

  name      = "pgbouncer.enabled"
  server_id = var.server.id
  value     = var.enable_pgbouncer
}

resource "azurerm_postgresql_flexible_server_configuration" "default_pool_size" {
  count = local.pgbouncer_available && var.enable_pgbouncer ? 1 : 0

  name      = "pgbouncer.default_pool_size"
  server_id = var.server.id
  value     = 4950
}

resource "azurerm_postgresql_flexible_server_configuration" "server_idle_timeout" {
  count = local.pgbouncer_available && var.enable_pgbouncer ? 1 : 0

  name      = "pgbouncer.server_idle_timeout"
  server_id = var.server.id
  value     = 30
}

resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer_diagnostics" {
  count = local.pgbouncer_available && var.enable_pgbouncer ? 1 : 0

  name      = "metrics.pgbouncer_diagnostics"
  server_id = var.server.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "extensions" {
  name      = "azure.extensions"
  server_id = var.server.id
  value     = "citext,pg_trgm,postgis,timescaledb,hstore,uuid-ossp,plpgsql,pg_stat_statements,vector"
}

resource "azurerm_postgresql_flexible_server_configuration" "idle_in_transaction_session_timeout" {
  name      = "idle_in_transaction_session_timeout"
  server_id = var.server.id
  value     = 3600000
}

resource "azurerm_postgresql_flexible_server_configuration" "idle_session_timeout" {
  name      = "idle_session_timeout"
  server_id = var.server.id
  value     = 3600000
}

resource "azurerm_postgresql_flexible_server_configuration" "pg_qs_parameters_capture_mode" {
  name      = "pg_qs.query_capture_mode"
  server_id = var.server.id
  value     = "TOP"
}

resource "azurerm_postgresql_flexible_server_configuration" "pgms_wait_sampling_query_capture_mode" {
  name      = "pgms_wait_sampling.query_capture_mode"
  server_id = var.server.id
  value     = "ALL"
}

resource "azurerm_postgresql_flexible_server_configuration" "track_io_timing" {
  name      = "track_io_timing"
  server_id = var.server.id
  value     = "on"
}