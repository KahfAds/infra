data "azurerm_container_registry" "accessible" {
  count = length(var.accessible_registries)
  name                = var.accessible_registries[count.index]
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "acr" {
  count = length(var.accessible_registries)
  principal_id         = azurerm_user_assigned_identity.this.principal_id
  role_definition_name = "AcrPull"
  scope                = data.azurerm_container_registry.accessible[count.index].id
}