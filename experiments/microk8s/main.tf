locals {
  location = "southeastasia"
}

resource "azurerm_resource_group" "this" {
  location = local.location
  name     = "microk8s-v1"
}

module "ssh" {
  source = "../../modules/ssh-keys/azure/v1"
  location = local.location
  name_prefix = "microk8s-v1"
  resource_group_name = azurerm_resource_group.this.name
}

module "initiator_node" {
  source = "../../modules/vm/azure/v1"
  admin_username = "azure-user"
  allowed_ports = [
    {
      name = "ssh"
      port = 22
      protocol = "Tcp"
      public = true
    },
    {
      name = "web"
      port = 80
      protocol = "Tcp"
      public = true
    },
    {
      name = "websecure"
      port = 443
      protocol = "Tcp"
      public = true
    },
    {
      name = "microk8s-cluster"
      port = 25000
      protocol = "Tcp"
      public = true
    },
    {
      name = "k8s"
      port = 16443
      protocol = "Tcp"
      public = true
    }
  ]
  name_prefix = "microk8s-initiator"
  network = {
    prefix = module.core_network.vnet_address_space[0]
  }
  private_ip_address = cidrhost(local.subnets[0].prefix, 10)
  private_key_pem = module.ssh.private_key_pem
  public_key = module.ssh.public_key
  resource_group_name = azurerm_resource_group.this.name
  subnet = {
    id     = module.core_network.vnet_subnets[0]
    prefix = local.subnets[0].prefix
  }
  publicly_accessible = true
}