resource "null_resource" "AllowNfsV3" {
  provisioner "local-exec" {
    command = "az feature register --namespace Microsoft.Storage --name AllowNfsV3"
  }
}

resource "null_resource" "PremiumHns" {
  provisioner "local-exec" {
    command = "az feature register --namespace Microsoft.Storage --name PremiumHns"
  }

  depends_on = [null_resource.PremiumHns]
}

resource "time_sleep" "wait_for_features" {
  depends_on      = [null_resource.AllowNfsV3]
  create_duration = "60s"
}

variable "resource_group" {
  type = object({
    name = string
    location = string
  })
}

resource "azurerm_private_dns_zone" "this" {
  name                = "${var.name_prefix}-privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group.name
}

variable "vnet_id" {}

variable "name_prefix" {}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = "${var.name_prefix}-vnet-link"
  resource_group_name   = azurerm_storage_account.this.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = var.vnet_id
}

variable "subnets" {
  type = list(object({
    id = string
    name = string
  }))
}

variable "allowed_ips" {
  type = list(string)
  default = ["114.130.0.0/16", "103.29.60.7/26", "182.160.101.179/26", "59.152.0.0/16", "103.125.0.0/16"]
}

resource "azurerm_storage_account" "this" {
  depends_on = [time_sleep.wait_for_features]

  account_replication_type      = "LRS"
  account_tier                  = "Standard"
  location                      = var.resource_group.location
  name                          = substr("${var.name_prefix}storage", 0, 23)
  resource_group_name           = var.resource_group.name
  account_kind                  = "StorageV2"
  nfsv3_enabled                 = true
  is_hns_enabled                = true
  public_network_access_enabled = true
  enable_https_traffic_only     = false

  network_rules {
    default_action             = "Deny" # Revert to "Deny" After creating all the containers.
    virtual_network_subnet_ids = var.subnets.*.id
    ip_rules                   = var.allowed_ips
    bypass                     = ["Logging", "Metrics", "AzureServices"]
  }
}

resource "azurerm_private_endpoint" "this" {
  count = length(var.subnets)

  name                = "${var.name_prefix}-nfs-private-endpoint-${var.subnets[count.index].name}"
  location            = azurerm_storage_account.this.location
  resource_group_name = azurerm_storage_account.this.resource_group_name
  subnet_id           = var.subnets[count.index].id

  private_service_connection {
    name                           = "${var.name_prefix}-blob-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
}

resource "azurerm_private_dns_a_record" "this" {
  name                = azurerm_storage_account.this.name
  zone_name           = azurerm_private_dns_zone.this.name
  resource_group_name = azurerm_storage_account.this.resource_group_name
  ttl                 = 300
  records             = azurerm_private_endpoint.this.*.private_service_connection.0.private_ip_address
}

variable "containers" {
  type = list(string)
  default = []
}

resource "azurerm_storage_container" "this" {
  for_each = { for container in var.containers: container => container }
  name                  = each.key
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

output "endpoint" {
  value = "${azurerm_private_dns_a_record.this.name}.${azurerm_private_dns_zone.this.name}"
}

output "account" {
  value = azurerm_storage_account.this.name
}