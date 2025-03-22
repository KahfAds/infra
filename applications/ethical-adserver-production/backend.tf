resource "azurerm_storage_container" "redis_data" {
  name                 = "redis-data"
  storage_account_name = module.nfs.account
}