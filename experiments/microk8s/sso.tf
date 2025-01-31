locals {
  ssh = {
    user = local.admin_username
    private_key_pem = module.ssh.private_key_pem
  }
}

module "sso_node" {
  source = "../../modules/vm/azure/v1"
  admin_username = "azure-user"
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
      name = "web"
      port = 80
      protocol = "Tcp"
      source_address_prefix = "*"
    },
    {
      access = "Allow"
      name = "websecure"
      port = 443
      protocol = "Tcp"
      source_address_prefix = "*"
    }
  ]
  name_prefix = "goauthentik"
  network = {
    prefix = module.core_network.vnet_address_space[0]
  }
  private_key_pem = module.ssh.private_key_pem
  public_key = module.ssh.public_key
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

module "sso_docker_setup" {
  depends_on = [module.sso_node]

  source = "../../modules/vm/post-setup/debian/docker/v1"
  ssh = merge( local.ssh, {
    host = module.sso_node.ssh.host
  })
}

locals {
  sso_domain = "auth.ababil.xyz"
}

module "auth_setup" {
  depends_on = [module.sso_docker_setup]

  source = "../../modules/vm/post-setup/on-docker/goauthentik/v1"
  authentik_domain = local.sso_domain
  letsencrypt_email = "mazharul@kahf.co"
  ssh = merge( local.ssh, {
    host = module.sso_node.ssh.host
  })
  admin_email = "mazharul@kahf.co"
}

output "sso" {
  value = {
    ip_address = module.sso_node.ssh.host
    domain = local.sso_domain
    token = module.auth_setup.token
    secret_key = module.auth_setup.secret_key
    password = module.auth_setup.password
  }
  sensitive = true
}