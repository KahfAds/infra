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

module "server_parameters" {
  count = var.replica_count

  source = "../server-parameters"
  max_connections = 4999
  server = {
    id = azurerm_postgresql_flexible_server.this[count.index].id
    sku_name = azurerm_postgresql_flexible_server.this[count.index].sku_name
  }
}

output "endpoints" {
  value = azurerm_postgresql_flexible_server.this.*.fqdn
}