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

resource "local_file" "ssh_key_pem" {
  filename = "${path.module}/ssh-keys/initiator.pem"
  content = module.ssh.private_key_pem
}

locals {
  admin_username = "azure-user"
}

module "initiator_node" {
  source = "../../modules/vm/azure/v1"
  admin_username = local.admin_username
  allowed_ports = local.allowed_ports
  name_prefix = "microk8s-initiator"
  network = {
    prefix = module.core_network.vnet_address_space[0]
  }
  private_ip_address = cidrhost(local.subnets[0].prefix, 10)
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

module "master_nodes" {
  count = 0
  source = "../../modules/vm/azure/v1"
  admin_username = local.admin_username
  allowed_ports = local.allowed_ports
  name_prefix = "microk8s-master-${count.index+1}"
  network = {
    prefix = module.core_network.vnet_address_space[0]
  }
  private_ip_address = cidrhost(local.subnets[0].prefix, 10+count.index+1)
  private_key_pem = module.ssh.private_key_pem
  public_key = module.ssh.public_key
  resource_group_name = azurerm_resource_group.this.name
  subnet = {
    id     = module.core_network.vnet_subnets[0]
    prefix = local.subnets[0].prefix
  }
  publicly_accessible = true
}

module "micro_k8s" {
  source = "../../modules/microk8s/v1"
  addons = [
    "traefik",
    "community",
    "dns",
    "prometheus",
    "cert-manager",
    "hostpath-storage",
    "helm ",
    "helm3",
    "nfs"
  ]
  master_nodes = [for ssh in module.master_nodes.*.ssh:
    {
      host = ssh.host
      user = local.admin_username
      private_key = module.ssh.private_key_pem
      private_ip = ssh.private_ip_address
      hostname = ssh.hostname
    }
  ]
  initiator_node = {
    host = module.initiator_node.ssh.host
    user = local.admin_username
    private_key = module.ssh.private_key_pem
    private_ip = module.initiator_node.ssh.private_ip_address
    hostname = module.initiator_node.ssh.hostname
  }
  install_channel = "1.30/stable"
}

module "load_balancer" {
  depends_on = [module.micro_k8s]
  source = "../../modules/load-balancers/azure/v1"
  exposed_ports = [
    {
      frontend_port = 80
      backend_port = module.micro_k8s.ingress.web_port
      protocol = "Tcp"
      name = "web"
    },
    {
      frontend_port = 443
      backend_port = module.micro_k8s.ingress.websecure_port
      protocol = "Tcp"
      name = "websecure"
    },
    {
      frontend_port = 8080
      backend_port = module.micro_k8s.ingress.dashboard_port
      protocol = "Tcp"
      name = "proxy"
    }
  ]
  location = azurerm_resource_group.this.location
  name_prefix = "microk8s-v1"
  network_interfaces = concat(module.master_nodes.*.network_interface, [module.initiator_node.network_interface])
  resource_group_name = azurerm_resource_group.this.name
}

output "k8s" {
  value = {
    initiator = module.initiator_node.ssh.host
    token = module.micro_k8s.token
  }
}