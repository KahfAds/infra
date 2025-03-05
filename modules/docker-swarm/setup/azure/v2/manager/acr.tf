locals {
  registry_login = concat(
    [
      "sudo apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg",
      "curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null",
      "export AZ_REPO=$(lsb_release -cs)",
      "echo 'deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ jammy main' | sudo tee /etc/apt/sources.list.d/azure-cli.list",
      "sudo apt-get update",
      "sudo apt-get install -y azure-cli",
      "sudo az login --identity"
    ],
    [
      for registry_name in var.accessible_registries:
      "sudo az acr login --name ${lower(registry_name)}"
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

module "periodic_login_azure_acr" {
  depends_on = [azurerm_linux_virtual_machine.leader]

  count = length(var.accessible_registries)
  source = "../../../../../vm/post-setup/debian/cronjob"

  cron_job = {
    name = "acr-login-${var.accessible_registries[count.index]}"
    command = "az acr login --name ${var.accessible_registries[count.index]}"
    run_as_user = "root"
    schedule = "*/10 * * * *" # every 10 minutes
  }

  ssh = {
    host = azurerm_public_ip.primary.ip_address
    user = local.admin_username
    private_key_pem = module.ssh_key.private_key_pem
  }
}