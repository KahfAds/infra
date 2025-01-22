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

module "micro_k8s" {
  source = "../../modules/microk8s/v1"
  addons = [
    "traefik",
    "community",
    "dns",
    "prometheus",
    "cert-manager",
    "storage",
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
  ingress = local.ingress
  install_channel = "1.32/stable"
  additional_cluster_domains = ["cluster.kahfads.com"]
  additional_cluster_ip_addresses = [module.load_balancer_cluster.public_ip]
}

module "load_balancer_workloads" {
  depends_on = [module.initiator_node, module.master_nodes]
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
    },
    {
      frontend_port = 8080
      backend_port = local.ingress.dashboard_port
      protocol = "Tcp"
      name = "proxy"
    }
  ]
  location = azurerm_resource_group.this.location
  name_prefix = "microk8s-v1"
  network_interfaces = concat(module.master_nodes.*.network_interface, [module.initiator_node.network_interface])
  resource_group_name = azurerm_resource_group.this.name
}

module "load_balancer_cluster" {
  depends_on = [module.initiator_node, module.master_nodes]
  source = "../../modules/load-balancers/azure/v1"
  exposed_ports = [
    {
      frontend_port = 443
      backend_port = 16443
      protocol = "Tcp"
      name = "cluster"
    }
  ]
  location = azurerm_resource_group.this.location
  name_prefix = "microk8s-v1-cluster"
  network_interfaces = concat(module.master_nodes.*.network_interface, [module.initiator_node.network_interface])
  resource_group_name = azurerm_resource_group.this.name
}

resource "local_file" "kubeconfig" {
  filename = "~/.kube/config"
  content = replace(module.micro_k8s.kubeconfig, "127.0.0.1:16443", "${module.load_balancer_cluster.public_ip}:443")
}
