output "worker_join_command" {
  value = data.external.worker_join_command.result.output
}

output "ssh" {
  value = {
    private_key_pem = module.ssh_key.private_key_pem
    username        = local.admin_username
    ip_address      = azurerm_public_ip.primary.ip_address
  }
}

output "docker" {
  value = {
    host    = azurerm_public_ip.primary.ip_address
    cert    = tls_locally_signed_cert.client_cert.cert_pem
    key     = tls_private_key.client_key.private_key_pem
    ca_cert = tls_self_signed_cert.ca_cert.cert_pem
  }
}