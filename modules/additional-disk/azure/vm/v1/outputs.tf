output "disk_id" {
  value = azurerm_managed_disk.this.id
}

output "attachment_id" {
  value = azurerm_virtual_machine_data_disk_attachment.this.id
}