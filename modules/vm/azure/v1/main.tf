resource "azurerm_linux_virtual_machine" "this" {
  name                            = "${var.name_prefix}-vm"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.size
  disable_password_authentication = true
  availability_set_id             = var.availability_set_id

  network_interface_ids = [var.network_interface.id]

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  os_disk {
    caching              = "ReadOnly"
    storage_account_type = "Standard_LRS"
    diff_disk_settings {
      option = "Local"
    }
  }

  computer_name  = var.name_prefix
  admin_username = var.admin_username

  admin_ssh_key {
    username = var.admin_username
    public_key = var.public_key
  }

  custom_data = length(var.custom_data) > 0 ? base64encode(var.custom_data) : null

  connection {
    user = var.admin_username
    type = "ssh"
    host = var.network_interface.public_ip_address
    private_key = file(var.private_key_location)
  }

  provisioner "remote-exec" {
    scripts = var.remote_exec_scripts
  }

  provisioner "local-exec" {
    command = var.local_exec_command
  }

  tags = {
    environment = terraform.workspace
  }
}

output "public_ip_address" {
  value = var.network_interface.public_ip_address
}