resource "azurerm_container_registry" "revive_ad_server" {
  name                = "kahfAdsProduction"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "Basic"
  admin_enabled       = false
}

module "container_registry_credentials" {
  source = "../../modules/azure/ad/service_principal"

  name_prefix = "revive-adserver-docker-terraform"
  scope_id    = azurerm_container_registry.revive_ad_server.id
  role_definition_name = "Contributor"
}

locals {
  registry = {
    address = azurerm_container_registry.revive_ad_server.login_server
    username = module.container_registry_credentials.client_id
    password = module.container_registry_credentials.client_secret
  }
}