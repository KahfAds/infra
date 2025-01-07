locals {
  env = "test"

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
      name = "microk8s-cluster"
      port = 25000
      protocol = "Tcp"
      source_address_prefix = module.core_network.vnet_address_space[0]
    },
    {
      access = "Deny"
      name = "microk8s-cluster-internet"
      port = 25000
      protocol = "Tcp"
      source_address_prefix = "Internet"
    },
    {
      access = "Allow"
      name = "k8s"
      port = 16443
      protocol = "Tcp"
      source_address_prefix = "*"
    },
    {
      access = "Allow"
      name = "ingress-dashboard"
      port = local.ingress.dashboard_port
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
    }
  ]

  ingress = {
    web_port = 30080
    websecure_port = 30443
    dashboard_port = 30880
  }
}