output "azurerm_user_assigned_identity" {
  value = {
    master_node = {
      client_id = azurerm_user_assigned_identity.master_node.client_id
    }
  }
}

output "resource_group" {
  value = {
    name = azurerm_resource_group.this.name
  }
}

output "subnet" {
  value = ""
}