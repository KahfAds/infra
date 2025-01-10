variable "resource_group" {
  type = object({
    name = string
    location = string
  })
}

variable "vm" {
  type = object({
    id = string
  })
}

resource "azurerm_managed_disk" "data_disk" {
  name                 = "data-disk-1"
  location             = var.resource_group.location
  resource_group_name  = var.resource_group.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 100
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attach" {
  managed_disk_id    = azurerm_managed_disk.data_disk.id
  virtual_machine_id = var.vm.id
  lun                = 0
  caching            = "ReadWrite"
}