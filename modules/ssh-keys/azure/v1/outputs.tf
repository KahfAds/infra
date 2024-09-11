output "id" {
  value = azurerm_ssh_public_key.this.id
}

output "public_key" {
  value = azurerm_ssh_public_key.this.public_key
}

output "private_key_location" {
  value = pathexpand("~/.ssh/${azurerm_ssh_public_key.this.name}.pem")
}
