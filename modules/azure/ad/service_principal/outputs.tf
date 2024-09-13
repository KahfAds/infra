output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "client_id" {
  value = azuread_service_principal.this.client_id
}

output "client_secret" {
  value = azuread_service_principal_password.this.value
}