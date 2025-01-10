resource "azurerm_user_assigned_identity" "master_node" {
  name                = "microk8s-csi-identity"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_role_assignment" "master_node" {
  principal_id   = azurerm_user_assigned_identity.master_node.principal_id
  role_definition_name = "Contributor"
  scope          = azurerm_resource_group.this.id
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
  additional_identities = {
    UserAssigned = [azurerm_user_assigned_identity.master_node.id]
  }
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
  additional_identities = {
    UserAssigned = [azurerm_user_assigned_identity.master_node.id]
  }
}