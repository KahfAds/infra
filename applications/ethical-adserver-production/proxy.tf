resource "random_password" "proxy" {
  length           = 12
  special          = true
  override_special = "_%@"
}

resource "azurerm_storage_container" "tarefik_tls" {
  name                 = "tarefik-tls"
  storage_account_name = module.nfs.account
}
