locals {
  admin_username = "azure-user"
}

module "ssh_key" {
  source              = "../../../../ssh-keys/azure/v1"
  location            = var.location
  name_prefix         = var.name_prefix
  resource_group_name = var.resource_group_name
}

resource "azurerm_availability_set" "this" {
  location                    = var.location
  name                        = "${var.name_prefix}-AS"
  resource_group_name         = var.resource_group_name
  platform_fault_domain_count = 2
}

resource "azurerm_linux_virtual_machine_scale_set" "node" {
  computer_name_prefix = var.name_prefix
  name                = "${var.name_prefix}-vmss"
  custom_data         = base64encode(templatefile("${path.module}/scripts/docker-install.sh", {
    JOIN_COMMAND = "sudo ${var.join_command}"
  }))
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.size
  instances           = var.scale.desired
  admin_username      = local.admin_username

  admin_ssh_key {
    username   = local.admin_username
    public_key = module.ssh_key.public_key
  }

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

  network_interface {
    name    = "${var.name_prefix}-nic"
    primary = true
    network_security_group_id = azurerm_network_security_group.node.id

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.subnet.id
    }
  }
}

resource "azurerm_network_security_group" "node" {
  name                = "${var.name_prefix}-node-sg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "NodeExporter"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9000-10000"
    source_address_prefix      = var.network.prefix
    destination_address_prefix = var.network.prefix
  }

  security_rule {
    name                       = "Loki"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3100"
    source_address_prefix      = var.network.prefix
    destination_address_prefix = var.network.prefix
  }

  security_rule {
    name                       = "Redis"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6379"
    source_address_prefix      = var.network.prefix
    destination_address_prefix = var.network.prefix
  }

  security_rule {
    name                       = "Swarm01"
    priority                   = 1007
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2376"
    source_address_prefix      = var.network.prefix
    destination_address_prefix = var.network.prefix
  }

  security_rule {
    name                       = "Swarm02"
    priority                   = 1008
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2377"
    source_address_prefix      = var.network.prefix
    destination_address_prefix = var.network.prefix
  }

  security_rule {
    name                       = "Swarm03"
    priority                   = 1009
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "7946"
    source_address_prefix      = var.network.prefix
    destination_address_prefix = var.network.prefix
  }

  security_rule {
    name                       = "Swarm04"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "7946"
    source_address_prefix      = var.network.prefix
    destination_address_prefix = var.network.prefix
  }

  security_rule {
    name                       = "Swarm05"
    priority                   = 1011
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "4789"
    source_address_prefix      = var.network.prefix
    destination_address_prefix = var.network.prefix
  }
}