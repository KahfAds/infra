resource "azurerm_availability_set" "this" {
  location                    = var.location
  name                        = "${var.name_prefix}-AS"
  resource_group_name         = var.resource_group_name
  platform_fault_domain_count = 2
}

resource "azurerm_linux_virtual_machine" "this" {
  name                            = "${var.name_prefix}-vm"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.size
  disable_password_authentication = true
  availability_set_id             = azurerm_availability_set.this.id

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
    caching              = "ReadWrite"
    disk_size_gb         = 200
    storage_account_type = "Standard_LRS"
  }

  computer_name  = var.name_prefix
  admin_username = var.admin_username

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.public_key
  }

  custom_data = length(var.custom_data) > 0 ? base64encode(var.custom_data) : null

  connection {
    user        = var.admin_username
    type        = "ssh"
    host        = var.publicly_accessible ? azurerm_public_ip.this[0].ip_address : var.private_ip_address
    private_key = var.private_key_pem
  }

  tags = {
    environment = terraform.workspace
  }
}

resource "azurerm_network_security_group" "this" {
  name                = "${var.name_prefix}-node-sg"
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "security_rule" {
    for_each = zipmap(range(length(var.allowed_ports)), var.allowed_ports)
    content {
      name                       = security_rule.value.name
      priority                   = 1000 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = security_rule.value.protocol
      source_port_range          = "*"
      destination_port_range     = tostring(security_rule.value.port)
      source_address_prefix      = security_rule.value.public ? "*" : var.network.prefix
      destination_address_prefix = security_rule.value.public ? "*" : var.network.prefix
    }
  }
}

resource "azurerm_public_ip" "this" {
  count               = var.publicly_accessible ? 1 : 0
  name                = "${var.name_prefix}-node-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "this" {
  name                = "${var.name_prefix}-node-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
    public_ip_address_id          = var.publicly_accessible ? azurerm_public_ip.this[0].id : null
  }
}

resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}