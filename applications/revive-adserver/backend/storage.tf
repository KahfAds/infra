resource "azurerm_storage_account" "this" {
  account_replication_type = "ZRS"
  account_tier             = "Standard"
  location                 = var.resource_group.location
  name                     = "revive-adserver-production"
  resource_group_name      = var.resource_group.name
}

resource "azurerm_storage_container" "admin_plugins" {
  name                 = "admin-plugins"
  storage_account_name = azurerm_storage_account.this.name
}

resource "azurerm_storage_container" "images" {
  name                 = "images"
  storage_account_name = azurerm_storage_account.this.name
}

resource "azurerm_storage_container" "plugins" {
  name                 = "plugins"
  storage_account_name = azurerm_storage_account.this.name
}

resource "azurerm_storage_container" "var" {
  name                 = "var"
  storage_account_name = azurerm_storage_account.this.name
}

resource "azurerm_storage_blob" "var_c" {
  name                   = "cache/keep"
  storage_account_name    = azurerm_storage_account.this.name
  storage_container_name  = azurerm_storage_container.var.name
  type                   = "Block"
  source                 = "${path.module}/keep"
}

resource "azurerm_storage_blob" "var_p_dj" {
  name                   = "plugins/DataObjects/keep"
  storage_account_name    = azurerm_storage_account.this.name
  storage_container_name  = azurerm_storage_container.var.name
  type                   = "Block"
  source                 = "${path.module}/keep"
}

resource "azurerm_storage_blob" "var_p_r" {
  name                   = "plugins/recover/keep"
  storage_account_name    = azurerm_storage_account.this.name
  storage_container_name  = azurerm_storage_container.var.name
  type                   = "Block"
  source                 = "${path.module}/keep"
}
