variable "location" {}

variable "resource_group_name" {}

variable "name_prefix" {}

variable "exposed_ports" {
  type = object({
    frontend_port = number
    backend_port = number
    protocol = string
    name = string
  })
}

variable "network_interfaces" {
  type = list(object({
    id = string
    ip_configuration_name = string
  }))
}

resource "azurerm_public_ip" "this" {
  name                = "${var.name_prefix}-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  lifecycle {
    prevent_destroy   = true
  }
}

resource "azurerm_lb" "this" {
  name                = "${var.name_prefix}-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "primary"
    public_ip_address_id = azurerm_public_ip.this.id
  }
}

resource "azurerm_lb_backend_address_pool" "this" {
  loadbalancer_id = azurerm_lb.this.id
  name            = "${var.name_prefix}-backend-pool"
}

resource "azurerm_lb_probe" "this" {
  count = length(var.exposed_ports)
  name                = "${var.name_prefix}-probe-${var.exposed_ports[count.index].name}"
  protocol            = var.exposed_ports[count.index].protocol
  port                = var.exposed_ports[count.index].backend_port
  loadbalancer_id     = azurerm_lb.this.id
}

resource "azurerm_lb_rule" "this" {
  count = length(var.exposed_ports)
  name                           = var.exposed_ports[count.index].name
  protocol                       = var.exposed_ports[count.index].protocol
  frontend_port                  = var.exposed_ports[count.index].frontend_port
  backend_port                   = var.exposed_ports[count.index].backend_port
  frontend_ip_configuration_name = azurerm_lb.this.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this.id]
  probe_id                       = azurerm_lb_probe.this[count.index].id
  loadbalancer_id                = azurerm_lb.this.id
}

resource "azurerm_network_interface_backend_address_pool_association" "this" {
  count = length(var.network_interfaces)
  network_interface_id    = var.network_interfaces[count.index].id
  ip_configuration_name   = var.network_interfaces[count.index].ip_configuration_name
  backend_address_pool_id = azurerm_lb_backend_address_pool.this.id
}