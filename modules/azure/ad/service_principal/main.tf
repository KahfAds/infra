resource "azuread_application" "this" {
  display_name = "${var.name_prefix}-app"
  owners = [data.azuread_client_config.this.object_id]
}

resource "azuread_service_principal" "this" {
  client_id = azuread_application.this.client_id
  owners = [data.azuread_client_config.this.object_id]
}

resource "azuread_service_principal_password" "this" {
  service_principal_id = azuread_service_principal.this.id
  end_date             = var.password_expiration_date
}

resource "azurerm_role_assignment" "this" {
  scope                = var.scope_id
  role_definition_name = var.role_definition_name
  principal_id         = azuread_service_principal.this.id
}