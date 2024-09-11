locals {
  admin_username = "azure-user"
}

module "ssh_key" {
  source              = "../../../ssh-keys/azure/v1"
  location            = var.location
  name_prefix         = "${var.name_prefix}-swarm-cluster"
  resource_group_name = var.resource_group_name
}

# data "template_file" "manager_node" {
#   filename = "${path.module}/manager-node-init.sh.tpl"
#   vars = {
#     PRIVATE_IP = azurerm_network_interface.manager_node.private_ip_address
#   }
# }

data "template_file" "join_tokens" {
  template = "${path.module}/join-tokens.sh.tpl"
  vars = {
    private_key_location = module.ssh_key.private_key_location
    username             = local.admin_username
    public_ip            = azurerm_public_ip.manager_node.ip_address
    worker_output_file          = "${path.module}/worker-token.txt"
    manager_output_file          = "${path.module}/manager-token.txt"
  }
}

resource "azurerm_availability_set" "manager" {
  location            = var.location
  name                = "${var.name_prefix}-docker-swarm-manager"
  resource_group_name = var.resource_group_name
  platform_fault_domain_count = 2
}

module "manager-node" {
  source                 = "../../../vm/azure/v1"
  admin_username         = local.admin_username
  availability_set_id    = azurerm_availability_set.manager.id
  name_prefix            = "${var.name_prefix}-docker-swarm-manager-node"
  public_key             = module.ssh_key.public_key
  resource_group_name    = var.resource_group_name
  subnet_id              = var.subnet.id
#   custom_data            = data.template_file.manager_node.rendered
  private_key_location   = module.ssh_key.private_key_location
  remote_exec_scripts = [
    "${path.module}/scripts/docker-install.sh",
    "${path.module}/scripts/start-swarm.sh"
  ]
  local_exec_command = <<EOT
    ssh -i ${module.ssh_key.private_key_location} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${local.admin_username}@${azurerm_public_ip.manager_node.ip_address} 'sudo docker swarm join-token -q worker' > ${path.module}/worker-token.txt && \
    ssh -i ${module.ssh_key.private_key_location} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${local.admin_username}@${azurerm_public_ip.manager_node.ip_address} 'sudo docker swarm join-token -q manager' > ${path.module}/manager-token.txt
  EOT
  network_interface = {
    id = azurerm_network_interface.manager_node.id
    public_ip_address = azurerm_public_ip.manager_node.ip_address
  }
}

resource "azurerm_network_interface" "manager_node" {
  name                = "${var.name_prefix}-docker-swarm-manager-node-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.manager_0_private_ip
    public_ip_address_id          = azurerm_public_ip.manager_node.id
  }
}

resource "azurerm_public_ip" "manager_node" {
  name                = "${var.name_prefix}-docker-swarm-manager-node-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "manager_node" {
  name                = "${var.name_prefix}-docker-swarm-manager-node-sg"
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

resource "azurerm_network_interface_security_group_association" "manager_node" {
  network_interface_id      = azurerm_network_interface.manager_node.id
  network_security_group_id = azurerm_network_security_group.manager_node.id
}