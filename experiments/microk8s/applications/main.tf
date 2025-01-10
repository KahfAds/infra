module "azure_disk_csi_driver" {
  source = "../../../modules/k8s-applications/azure/csi-driver"
  client_id = data.terraform_remote_state.micro_k8s_v1.outputs.azurerm_user_assigned_identity.master_node.client_id
  namespace = "kube-system"
  resource_group_name = data.terraform_remote_state.micro_k8s_v1.outputs.resource_group.name
  subnet_name = "subnet1"
  vnet_name = "acctvnet"
}