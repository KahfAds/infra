locals {
  admin_username = "azure-user"
  program = [
    "ssh",
    "-i",
    module.ssh_key.private_key_location,
    "-o",
    "StrictHostKeyChecking=no",
    "-o",
    "UserKnownHostsFile=/dev/null",
    "${local.admin_username}@${azurerm_public_ip.node.ip_address}", <<EOF
        eval "$(jq -r '@sh "ARGS=\(.args)"')"
        jq -n --arg output "$(sudo docker swarm join-token $ARGS)" '{"output":$output}'
    EOF
  ]
}

module "ssh_key" {
  source              = "../../../../ssh-keys/azure/v1"
  location            = var.location
  name_prefix         = var.name_prefix
  resource_group_name = var.resource_group_name
}

resource "azurerm_availability_set" "this" {
  location            = var.location
  name                = "${var.name_prefix}-AS"
  resource_group_name = var.resource_group_name
  platform_fault_domain_count = 2
}

module "node" {
  source                 = "../../../../vm/azure/v1"
  admin_username         = local.admin_username
  availability_set_id    = azurerm_availability_set.this.id
  name_prefix            = "${var.name_prefix}-node"
  public_key             = module.ssh_key.public_key
  resource_group_name    = var.resource_group_name
  subnet_id              = var.subnet.id
  private_key_location   = module.ssh_key.private_key_location
  remote_exec_scripts = [
    "${path.module}/scripts/docker-install.sh",
    "${path.module}/scripts/start-swarm.sh"
  ]
  network_interface = {
    id = azurerm_network_interface.node.id
    public_ip_address = azurerm_public_ip.node.ip_address
  }
}

data "external" "worker_join_command" {
  depends_on = [module.node]
  program = local.program
  query = {
    args = "worker"
  }
}

data "external" "join_command" {
  depends_on = [module.node]
  program = local.program
  query = {
    args = "manager"
  }
}

resource "azurerm_network_interface" "node" {
  name                = "${var.name_prefix}-node-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
    public_ip_address_id          = azurerm_public_ip.node.id
  }
}

resource "azurerm_public_ip" "node" {
  name                = "${var.name_prefix}-node-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
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
    name                       = "Swarm01"
    priority                   = 1002
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
# these will be added in worker node
#   security_rule {
#     name                       = "HTTP"
#     priority                   = 1002
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "80"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
#
#   security_rule {
#     name                       = "HTTPS"
#     priority                   = 1003
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "443"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
#
#   security_rule {
#     name                       = "NodeExporter"
#     priority                   = 1004
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "9000-10000"
#     source_address_prefix      = var.subnet.prefix
#     destination_address_prefix = var.subnet.prefix
#   }
#
#
#   security_rule {
#     name                       = "Loki"
#     priority                   = 1006
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "3100"
#     source_address_prefix      = var.subnet.prefix
#     destination_address_prefix = var.subnet.prefix
#   }
#
#   security_rule {
#     name                       = "Redis"
#     priority                   = 1007
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "6379"
#     source_address_prefix      = var.subnet.prefix
#     destination_address_prefix = var.subnet.prefix
#   }
}

resource "azurerm_network_interface_security_group_association" "node" {
  network_interface_id      = azurerm_network_interface.node.id
  network_security_group_id = azurerm_network_security_group.node.id
}