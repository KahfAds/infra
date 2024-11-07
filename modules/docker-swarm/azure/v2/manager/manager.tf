resource "azurerm_linux_virtual_machine" "manager" {
  count = var.replica

  name                            = "${var.name_prefix}-vm-${count.index}"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.size
  disable_password_authentication = true
  availability_set_id             = azurerm_availability_set.this.id

  network_interface_ids = [azurerm_network_interface.manager[count.index].id]

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
  admin_username = local.admin_username

  admin_ssh_key {
    username   = local.admin_username
    public_key = module.ssh_key.public_key
  }

  connection {
    user        = local.admin_username
    type        = "ssh"
    host        = azurerm_public_ip.manager[count.index].ip_address
    private_key = module.ssh_key.private_key_pem
  }

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  provisioner "remote-exec" {
    inline = concat(
      local.docker_install,
      local.registry_login,
      ["sudo ${data.external.join_command.result.output}"]
    )
  }

  tags = {
    environment = terraform.workspace
  }
}

resource "azurerm_network_interface" "manager" {
  count = var.replica

  name                = "${var.name_prefix}-node-nic-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.manager[count.index].id
  }
}

resource "azurerm_public_ip" "manager" {
  count = var.replica

  name                = "${var.name_prefix}-node-public-ip-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface_security_group_association" "manager" {
  count = var.replica

  network_interface_id      = azurerm_network_interface.manager[count.index].id
  network_security_group_id = azurerm_network_security_group.primary.id
}
