output "id" {
  value = azurerm_ssh_public_key.this.id
}

output "public_key" {
  value = azurerm_ssh_public_key.this.public_key
}

output "private_key_pem" {
  value = tls_private_key.this.private_key_pem
  sensitive = false
}

output "private_key_openssh" {
  value = tls_private_key.this.private_key_openssh
}
