resource "null_resource" "stack_deployment" {
  depends_on = [azurerm_linux_virtual_machine.primary]
  for_each = var.deployed_stacks
  connection {
    user        = self.triggers.user_name
    type        = "ssh"
    host        = self.triggers.host
    private_key = self.triggers.private_key
  }

  provisioner "remote-exec" {
    when = create
    inline = concat(
      ["sudo az login --identity"],
      [
        for registry_name in var.accessible_registries :
        "sudo az acr login --name ${lower(registry_name)}"
      ],
      ["echo '${base64decode(each.value)}' | sudo docker stack deploy --with-registry-auth --compose-file - ${each.key}"]
    )
  }

  provisioner "remote-exec" {
    when = destroy
    inline = ["sudo docker stack rm ${self.triggers.key}"]
  }

  triggers = {
    user_name   = local.admin_username
    private_key = module.ssh_key.private_key_pem
    host        = azurerm_public_ip.primary.ip_address
    key         = each.key
    compose_file_content = base64decode(each.value)
  }
}