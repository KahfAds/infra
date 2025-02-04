module "load_balancer" {
  source = "../../modules/load-balancers/azure/v1"
  exposed_ports = [
    {
      frontend_port = 80
      backend_port = local.ingress.web_port
      protocol = "Tcp"
      name = "web"
    },
    {
      frontend_port = 443
      backend_port = local.ingress.websecure_port
      protocol = "Tcp"
      name = "websecure"
    }
  ]
  location = azurerm_resource_group.this.location
  name_prefix = "${local.name_prefix}-${local.env}"
  network_interfaces = module.swarm_cluster.network_interfaces.manager
  resource_group_name = azurerm_resource_group.this.name
}