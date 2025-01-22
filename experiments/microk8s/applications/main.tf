module "azure_csi_driver" {
  source = "../../../modules/k8s-applications/azure/csi-driver"
  client_id = data.terraform_remote_state.micro_k8s_v1.outputs.azurerm_user_assigned_identity.master_node.client_id
  namespace = "kube-system"
  resource_group_name = data.terraform_remote_state.micro_k8s_v1.outputs.resource_group.name
  subnet_name = "subnet1"
  vnet_name = "acctvnet"
}

module "traefik" {
  source = "../../../modules/k8s-applications/ingress-controllers/traefik"
}

module "cluster_issuer" {
  source = "../../../modules/k8s-applications/cluster_issuers/letsencrypt"
  acme_email = "mazharul@kahf.co"
  ingress_class = module.traefik.class_name
}