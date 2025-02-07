terraform {
  required_providers {
    ssh = {
      source = "loafoe/ssh"
      version = "2.7.0"
    }
  }
}

resource "ssh_resource" "docker_secrets" {
  depends_on = [azurerm_linux_virtual_machine.leader, module.ssh_key]

  host = azurerm_public_ip.primary.ip_address
  user = local.admin_username
  private_key = module.ssh_key.private_key_openssh
  agent = false
  commands = concat(local.commands.delete_all_secrets, local.commands.add_all_secrets)
  triggers = {
    secrets = md5(join(",", [for key, value in var.docker_secrets : "${key}=${value}"]))
  }
}