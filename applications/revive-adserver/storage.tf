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
  depends_on = [null_resource.AllowNfsV3]
  create_duration = "60s"
}

resource "azurerm_storage_account" "this" {
  depends_on = [time_sleep.wait_for_features, module.core_network]

  account_replication_type      = "LRS"
  account_tier                  = "Standard"
  location                      = azurerm_resource_group.this.location
  name                          = "reviveadserver02"
  resource_group_name           = azurerm_resource_group.this.name
  account_kind                  = "StorageV2"
  nfsv3_enabled                 = true
  is_hns_enabled                = true # Hierarchical Namespace enabled?
  public_network_access_enabled = true
  https_traffic_only_enabled    = false

  network_rules {
    default_action = "Deny" # Revert to "Deny" After creating all the containers.
    virtual_network_subnet_ids = module.core_network.vnet_subnets
    ip_rules = ["114.130.184.62/26"]
  }
}

resource "azurerm_private_dns_zone" "storage_blob_dns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "nfs_vnet_link" {
  name                  = "nfs-vnet-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob_dns.name
  virtual_network_id    = module.core_network.vnet_id
}

resource "azurerm_private_endpoint" "nfs_private_endpoint" {
  count = length(local.subnets)

  name                = "nfs-private-endpoint-${local.subnets[count.index].name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.core_network.vnet_subnets[count.index]

  private_service_connection {
    name                           = "blob-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names = ["blob"]
  }
}

resource "azurerm_private_dns_a_record" "nfs_dns_record" {
  name                = azurerm_storage_account.this.name
  zone_name           = azurerm_private_dns_zone.storage_blob_dns.name
  resource_group_name = azurerm_resource_group.this.name
  ttl                 = 300
  records             = azurerm_private_endpoint.nfs_private_endpoint.*.private_service_connection.0.private_ip_address
}


resource "azurerm_storage_container" "admin_plugins" {
  name                  = "admin-plugins"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "images" {
  name                  = "images"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "plugins" {
  name                  = "plugins"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "var" {
  name                  = "var"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "var_cache" {
  name                   = "cache/dummy.txt"
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = azurerm_storage_container.var.name
  type                   = "Block"
  source                 = "${path.module}/dummy.txt"
}

resource "azurerm_storage_blob" "var_plugins_DataObjects" {
  name                   = "plugins/DataObjects/dummy.txt"
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = azurerm_storage_container.var.name
  type                   = "Block"
  source                 = "${path.module}/dummy.txt"
}

resource "azurerm_storage_blob" "var_plugins_recover" {
  name                   = "plugins/recover/dummy.txt"
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = azurerm_storage_container.var.name
  type                   = "Block"
  source                 = "${path.module}/dummy.txt"
}
