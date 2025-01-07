resource "azurerm_public_ip" "load_balancer" {
  count = var.create_lb ? 1 : 0

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
  count = var.create_lb ? 1 : 0

  name                = "${var.name_prefix}-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "primary"
    public_ip_address_id = azurerm_public_ip.load_balancer[0].id
  }
}

resource "azurerm_lb_backend_address_pool" "this" {
  count = var.create_lb ? 1 : 0

  loadbalancer_id = azurerm_lb.this[0].id
  name            = "backend-pool"
}

resource "azurerm_lb_probe" "web_lb_probe_80" {
  count = var.create_lb ? 1 : 0

  name                = "tcp-probe-80"
  protocol            = "Tcp"
  port                = 80
  loadbalancer_id     = azurerm_lb.this[0].id
}

resource "azurerm_lb_probe" "web_lb_probe_443" {
  count = var.create_lb ? 1 : 0

  name                = "tcp-probe-443"
  protocol            = "Tcp"
  port                = 443
  loadbalancer_id     = azurerm_lb.this[0].id
}

resource "azurerm_lb_rule" "web" {
  count = var.create_lb ? 1 : 0

  name                           = "web"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.this[0].frontend_ip_configuration[0].name
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.this[0].id]
  probe_id                       = azurerm_lb_probe.web_lb_probe_80[0].id
  loadbalancer_id                = azurerm_lb.this[0].id
}

resource "azurerm_lb_rule" "websecure" {
  count = var.create_lb ? 1 : 0

  name                           = "websecure"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = azurerm_lb.this[0].frontend_ip_configuration[0].name
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.this[0].id]
  probe_id                       = azurerm_lb_probe.web_lb_probe_443[0].id
  loadbalancer_id                = azurerm_lb.this[0].id
}

resource "azurerm_network_interface_backend_address_pool_association" "primary" {
  count = var.create_lb ? 1 : 0

  network_interface_id    = azurerm_network_interface.primary.id
  ip_configuration_name   = azurerm_network_interface.primary.ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.this[0].id
}

resource "azurerm_network_interface_backend_address_pool_association" "manager" {
  count = (var.create_lb && var.replica > 0) ? var.replica : 0

  network_interface_id    = azurerm_network_interface.manager[count.index].id
  ip_configuration_name   = azurerm_network_interface.manager[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.this[0].id
}