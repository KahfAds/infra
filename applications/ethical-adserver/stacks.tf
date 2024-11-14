locals {
  stacks = {
    ethical_ad_server = base64encode(templatefile("${path.module}/stacks/ethical-adserver.yaml", {
      ENV                = local.env
      AZURE_ACCOUNT_NAME = module.blob.account
      AZURE_ACCOUNT_KEY = module.blob.primary_access_key
      AZURE_CONTAINER    = "ethicaladserver"
      SENDGRID_API_KEY   = var.sendgrid_api_key
      SECRET_KEY         = var.secret_key
      SERVER_EMAIL       = var.sender_email
      METABASE_SECRET_KEY = var.metabase_secret_key
      METABASE_EMBED_KEY = var.metabase_embed_key
      POSTGRES_HOST = azurerm_postgresql_flexible_server.this.fqdn
      POSTGRES_USER = local.database_user
      POSTGRES_PASSWORD = random_password.database.result
      DEFAULT_FILE_STORAGE_HOSTNAME = "media.kahfads.com"
    }))
    monitoring = base64encode(module.monitoring.stack)
    portainer     = base64encode(file("${path.module}/stacks/portainer.yaml"))
    prune         = base64encode(file("${path.module}/stacks/prune-nodes.yaml"))
    swarm-cronjob = base64encode(file("${path.module}/stacks/swarm-cronjob.yaml"))
    proxy         = local.stack_proxy
    logging = base64encode(templatefile("${path.module}/stacks/logging/docker-compose.yaml", {
      LOKI_CONFIG_NAME = docker_config.this[local.docker_configs.loki.name].name
      PROMTAIL_CONFIG_NAME = docker_config.this[local.docker_configs.promtail.name].name
    }))
    qrm = base64encode(module.qrm.stack)
  }
}

resource "null_resource" "stack_deployments" {
  depends_on = [module.swarm_cluster]
  for_each   = local.stacks
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
          azurerm_container_registry.this.name
        ] :
        "sudo az acr login --name ${lower(registry_name)}"
      ],
      [
        "echo '${nonsensitive(sensitive(base64decode(each.value)))}' | sudo docker stack deploy --with-registry-auth --prune --compose-file - ${each.key}"
      ]
    )
  }

  triggers = {
    user_name            = module.swarm_cluster.ssh.username
    private_key          = module.swarm_cluster.ssh.private_key_pem
    host                 = module.swarm_cluster.ssh.ip_addresses.leader
    key                  = each.key
    compose_file_content = base64decode(each.value)
  }
}

resource "null_resource" "stack_removal" {
  depends_on = [module.swarm_cluster]
  for_each   = local.stacks

  connection {
    user        = self.triggers.user_name
    type        = "ssh"
    host        = self.triggers.host
    private_key = self.triggers.private_key
  }

  provisioner "remote-exec" {
    when   = destroy
    inline = ["sudo docker stack rm ${each.key}"]
  }

  triggers = {
    user_name   = module.swarm_cluster.ssh.username
    private_key = module.swarm_cluster.ssh.private_key_pem
    host        = module.swarm_cluster.ssh.ip_addresses.leader
    key         = each.key
  }
}