locals {
  stacks = {
    proxy           = local.stack_proxy
    revive-adserver = local.stack_revive_ad_server
  }
}

resource "null_resource" "stack_deployments" {
  depends_on = [module.swarm_cluster]
  for_each = local.stacks
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
        for registry_name in [
          azurerm_container_registry.revive_ad_server.name
        ] :
        "sudo az acr login --name ${lower(registry_name)}"
      ],
      [
        "echo '${base64decode(each.value)}' | sudo docker stack deploy --with-registry-auth --compose-file - ${each.key}"
      ]
    )
  }

  provisioner "remote-exec" {
    when = destroy
    inline = ["sudo docker stack rm ${self.triggers.key}"]
  }

  triggers = {
    user_name   = module.swarm_cluster.ssh.username
    private_key = module.swarm_cluster.ssh.private_key_pem
    host        = module.swarm_cluster.ssh.ip_address
    key         = each.key
    compose_file_content = base64decode(each.value)
  }
}