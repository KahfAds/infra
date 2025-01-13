data "terraform_remote_state" "micro_k8s_v1" {
  backend = "azurerm"

  config = {
    resource_group_name  = "microk8s-v1-tf"
    storage_account_name = "microk8sterraform"
    container_name       = "terraform"
    key                  = "prod.terraform.tfstate"
  }
}

data "kubernetes_nodes" "all" {}

locals {
  manager_ips = [for node in data.kubernetes_nodes.all.nodes :
    node.status[0].addresses[0].address
    if contains(keys(node.metadata[0].labels), "node-role.kubernetes.io/control-plane")
  ]

  worker_ips = [for node in data.kubernetes_nodes.all.nodes :
    node.status[0].addresses[0].address
    if !contains(keys(node.metadata[0].labels), "node-role.kubernetes.io/control-plane")
  ]
}

output "manager_ips" {
  value = local.manager_ips
}

output "worker_ips" {
  value = local.worker_ips
}
