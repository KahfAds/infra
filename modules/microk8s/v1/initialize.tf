resource "azurerm_linux_virtual_machine" "leader" {
  name                            = "${var.name_prefix}-vm"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.size
  disable_password_authentication = true
  availability_set_id             = azurerm_availability_set.this.id

  network_interface_ids = [azurerm_network_interface.primary.id]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  os_disk {
    caching              = "ReadWrite"
    disk_size_gb = 200
    storage_account_type = "Standard_LRS"
  }

  computer_name  = var.name_prefix
  admin_username = local.admin_username

  admin_ssh_key {
    username   = local.admin_username
    public_key = module.ssh_key.public_key
  }

  connection {
    user        = local.admin_username
    type        = "ssh"
    host        = azurerm_public_ip.primary.ip_address
    private_key = module.ssh_key.private_key_pem
  }

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  provisioner "remote-exec" {
    inline = ["sleep 60"]  # Adjust the delay time as needed
  }

  provisioner "remote-exec" {
    inline = concat(
      ["sudo hostnamectl set-hostname ${self.name}"],
      local.docker_install,
      local.docker_plugins,
      local.swarm_init,
      local.registry_login
    )
  }

  tags = {
    environment = terraform.workspace
  }
}