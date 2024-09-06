resource "azurerm_linux_virtual_machine" "this" {
  name                            = "${var.name_prefix}-vm"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.size
  disable_password_authentication = true
  availability_set_id             = var.availability_set_id

  network_interface_ids = [azurerm_network_interface.this.id]

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
    public_key = file("${var.rsa_key_name}.pub")
  }

  custom_data = length(var.custom_data) > 0 ? base64encode(var.custom_data) : null

  tags = {
    environment = terraform.workspace
  }
}

resource "azurerm_network_interface" "this" {
  name                = "${var.name_prefix}-vm-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "azurerm_public_ip" "this" {
  name                = "${var.name_prefix}-vm-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}