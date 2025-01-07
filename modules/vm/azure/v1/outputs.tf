output "ssh" {
  value = {
    host = var.publicly_accessible ? azurerm_public_ip.this[0].ip_address : azurerm_network_interface.this.private_ip_address
    private_ip_address = azurerm_network_interface.this.private_ip_address
    hostname = azurerm_linux_virtual_machine.this.computer_name
  }
}

output "network_interface" {
  value = {
    id = azurerm_network_interface.this.id
    ip_configuration_name = azurerm_network_interface.this.ip_configuration[0].name
  }
}