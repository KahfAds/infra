locals {
  registry_login = concat(
    [
      "sudo apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg",
      "curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null",
      "AZ_REPO=$(lsb_release -cs)",
      "echo \"deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main\" | sudo tee /etc/apt/sources.list.d/azure-cli.list",
      "sudo apt-get update",
      "sudo apt-get install -y azure-cli",
      "sudo az login --identity"
    ],
    [
      for registry_name in var.accessible_registries:
      "sudo az acr login --name ${registry_name} --identity"
    ]
  )
}

data "azurerm_container_registry" "accessible" {
  count = length(var.accessible_registries)
  name                = var.accessible_registries[count.index]
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "acr" {
  count = length(var.accessible_registries)
  principal_id         = azurerm_user_assigned_identity.this.principal_id
  role_definition_name = "AcrPull"
  scope                = data.azurerm_container_registry.accessible[count.index].id
}