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

data "external" "worker_join_command" {
  depends_on = [azurerm_linux_virtual_machine.leader]
  program = local.program
  query = {
    args = "worker"
  }
}

data "external" "join_command" {
  depends_on = [azurerm_linux_virtual_machine.leader]
  program = local.program
  query = {
    args = "manager"
  }
}

resource "azurerm_network_interface" "primary" {
  name                = "${var.name_prefix}-node-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
    public_ip_address_id          = azurerm_public_ip.primary.id
  }
}

resource "azurerm_public_ip" "primary" {
  name                = "${var.name_prefix}-node-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "primary" {
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
    name                       = "Swarm01"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2376"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Swarm02"
    priority                   = 1003
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
    priority                   = 1004
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
    priority                   = 1005
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
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "4789"
    source_address_prefix      = var.network.prefix
    destination_address_prefix = var.network.prefix
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1007
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
    priority                   = 1008
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "TRAEFIK"
    priority                   = 1009
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "TRAEFIK_PING"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8082"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                   = "Allow-DNS-TCP"
    priority               = 1011
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "Tcp"
    source_port_range      = "*"
    destination_port_range = "53"
    source_address_prefix  = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                   = "Allow-DNS-UDP"
    priority               = 1012
    direction              = "Inbound"
    access                 = "Allow"
    protocol               = "Udp"
    source_port_range      = "*"
    destination_port_range = "53"
    source_address_prefix  = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "DockerPrometheus"
    priority                   = 1013
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9323"
    source_address_prefix      = var.network.prefix
    destination_address_prefix = var.network.prefix
  }
  security_rule {
    name                       = "PrometheusNodeExporter"
    priority                   = 1014
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9100"
    source_address_prefix      = var.network.prefix
    destination_address_prefix = var.network.prefix
  }
}

resource "azurerm_network_interface_security_group_association" "node" {
  network_interface_id      = azurerm_network_interface.primary.id
  network_security_group_id = azurerm_network_security_group.primary.id
}