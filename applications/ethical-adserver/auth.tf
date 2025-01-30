locals {
  allowed_ports = [
    {
      access = "Allow"
      name = "ssh"
      port = 22
      protocol = "Tcp"
      source_address_prefix = "*"
    },
    {
      access = "Allow"
      name = "ingress-web"
      port = local.ingress.web_port
      protocol = "Tcp"
      source_address_prefix = "*"
    },
    {
      access = "Allow"
      name = "ingress-websecure"
      port = local.ingress.websecure_port
      protocol = "Tcp"
      source_address_prefix = "*"
    },
    {
      access = "Allow"
      name = "ingress-dashboard"
      port = local.ingress.dashboard_port
      protocol = "Tcp"
      source_address_prefix = "*"
    }
  ]
}

module "auth_node" {
  source = "../../modules/vm/azure/v1"
  admin_username = "azure-user"
  allowed_ports = local.allowed_ports
  name_prefix = "goauthentik"
  network = {
    prefix = module.core_network.vnet_address_space[0]
  }
  private_key_pem = module.swarm_cluster.ssh.private_key_pem
  public_key = module.swarm_cluster.ssh.public_key
  resource_group_name = azurerm_resource_group.this.name
  size = "Standard_B4ms"
  subnet = {
    id     = [
      for subnet in module.core_network.vnet_subnets :
      subnet if endswith(subnet, local.subnets[0].name)
    ][0]
    prefix = local.subnets[0].prefix
  }
  publicly_accessible = true
}

module "auth_setup" {
  depends_on = [module.auth_node]

  source = "../../modules/goauthentik/standalone/v1"
  authentik_domain = "auth.kahfads.com"
  letsencrypt_email = "mazharul@kahf.co"
  ssh = {
    host = module.auth_node.ssh.host
    user = module.swarm_cluster.ssh.username
    private_key_pem = module.swarm_cluster.ssh.private_key_pem
  }
}