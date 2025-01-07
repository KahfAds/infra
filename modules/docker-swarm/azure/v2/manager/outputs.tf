output "worker_join_command" {
  value = data.external.worker_join_command.result.output
}

output "manager_join_command" {
  value = data.external.join_command.result.output
}

output "ssh" {
  value = {
    private_key_pem = module.ssh_key.private_key_pem
    public_key = module.ssh_key.public_key
    username        = local.admin_username

    ip_addresses      = {
      leader = azurerm_public_ip.primary.ip_address
      managers = azurerm_public_ip.manager.*.ip_address
    }

    virtual_machines = concat([
      {
        initial_leader = true
        manager = true
        ip_address = azurerm_public_ip.primary.ip_address
        id = azurerm_linux_virtual_machine.leader.id
        hostname = azurerm_linux_virtual_machine.leader.name
        nic_name = azurerm_network_interface.primary.name
      }
    ], [ for idx, machine in azurerm_linux_virtual_machine.manager:
      {
        initial_leader = false
        manager = true
        ip_address = machine.public_ip_address
        id = machine.id
        hostname = machine.name
        nic_name = azurerm_network_interface.manager[idx].name
      }
    ])
  }
  sensitive = false
}

output "docker" {
  value = {
    host    = azurerm_public_ip.primary.ip_address
    cert    = tls_locally_signed_cert.client_cert.cert_pem
    key     = tls_private_key.client_key.private_key_pem
    ca_cert = tls_self_signed_cert.ca_cert.cert_pem
  }
  sensitive = false
}