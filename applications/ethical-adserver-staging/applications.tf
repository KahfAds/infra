locals {
  docker_configs = {
    loki = {
      name = "loki"
      content = file("${path.module}/stacks/monitoring/loki.yaml")
    }
    promtail = {
      name = "promtail"
      content = file("${path.module}/stacks/monitoring/promtail.yaml")
    }
    qrm_app = {
      name = "qrm_app"
      content = templatefile("${path.module}/stacks/qrm/.env", {
        APP_ENV                = "production"
        APP_KEY                = var.qrm.app_key
        APP_DEBUG              = false
        APP_URL                = local.qrm.app_url
        DB_CONNECTION          = "pgsql"
        DB_HOST                = azurerm_postgresql_flexible_server.this.fqdn
        DB_PORT                = 5432
        DB_DATABASE            = azurerm_postgresql_flexible_server_database.qr_code_management.name
        DB_USERNAME            = azurerm_postgresql_flexible_server.this.administrator_login
        DB_PASSWORD            = azurerm_postgresql_flexible_server.this.administrator_password
        MIX_PUSHER_APP_KEY     = "xxxx"
        MIX_PUSHER_APP_CLUSTER = "xxxx"
        IP_STACK_ACCESS_KEY    = var.qrm.ip_stack_access_key
      })
    },
    prometheus = {
      name = "prometheus"
      content = file("${path.module}/stacks/monitoring/prometheus.yaml")
    }
  }
}

provider "docker" {
  alias         = "swarm"
  host          = "tcp://${module.swarm_cluster.docker.host}:2376"
  cert_material = module.swarm_cluster.docker.cert
  ca_material   = module.swarm_cluster.docker.ca_cert
  key_material  = module.swarm_cluster.docker.key
}

resource "docker_config" "this" {
  provider = docker.swarm
  for_each = local.docker_configs

  data = base64encode(each.value.content)
  name = "${each.key}_${md5(each.value.content)}"

  lifecycle {
    create_before_destroy = true
  }
}

module "backend" {
  source = "./stacks/backend"
  docker = module.swarm_cluster.docker
  env      = local.env
  registry = local.registry
}

module "qrm" {
  source               = "./stacks/qrm"
  docker_config_name   = docker_config.this[local.docker_configs.qrm_app.name].name
  root_domain          = local.root_domain
  storage_account_name = module.nfs.account
  nfs_endpoint         = module.nfs.endpoint
  env                  = local.env
}

module "monitoring" {
  source                 = "./stacks/monitoring"
  storage_account_name   = module.nfs.account
  nfs_endpoint           = module.nfs.endpoint
  prometheus_config_name = docker_config.this[local.docker_configs.prometheus.name].name
  root_domain            = local.root_domain
  loki_config_name       = docker_config.this[local.docker_configs.loki.name].name
  loki_disk_mount_point  = local.loki_mount_point
  promtail_config_name   = docker_config.this[local.docker_configs.promtail.name].name
}

locals {
  stacks = {
    ethical_ad_server = base64encode(templatefile("${path.module}/stacks/backend/docker-compose.yaml", {
      ENV                 = local.env
      AZURE_ACCOUNT_NAME  = module.blob.account
      AZURE_ACCOUNT_KEY   = module.blob.primary_access_key
      AZURE_CONTAINER     = "ethicaladserver"
      SENDGRID_API_KEY    = var.sendgrid_api_key
      SECRET_KEY          = var.secret_key
      SERVER_EMAIL        = var.sender_email
      METABASE_SECRET_KEY = var.metabase_secret_key
      METABASE_EMBED_KEY  = var.metabase_embed_key
      POSTGRES_HOST       = azurerm_postgresql_flexible_server.this.fqdn
      POSTGRES_USER       = local.database_user
      POSTGRES_PASSWORD   = azurerm_postgresql_flexible_server.this.administrator_password
      ROOT_DOMAIN         = local.root_domain
      DEFAULT_FILE_STORAGE_HOSTNAME = "media.${local.root_domain}"
      SMTP_HOST = var.smtp.host
      SMTP_PORT = var.smtp.port
      SMTP_USER = var.smtp.username
      SMTP_PASSWORD = var.smtp.password
    }))
    monitoring = base64encode(module.monitoring.stack)
    portainer = base64encode(templatefile("${path.module}/stacks/portainer.yaml", {
      root_domain = local.root_domain
    }))
    docker_tasks = base64encode(templatefile("${path.module}/stacks/docker-tasks.yaml", {
      ADDRESS  = local.registry.address
      USERNAME = local.registry.username
      PASSWORD = local.registry.password
    }))
    swarm-cronjob = base64encode(file("${path.module}/stacks/swarm-cronjob.yaml"))
    qrm = base64encode(module.qrm.stack)
    autoscaler = base64encode(file("${path.module}/stacks/autoscaler.yaml"))
    proxy = local.stack_proxy
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
    user_name   = module.swarm_cluster.ssh.username
    private_key = module.swarm_cluster.ssh.private_key_pem
    host        = module.swarm_cluster.ssh.ip_addresses.leader
    key         = each.key
    compose_file_content = base64decode(each.value)
  }
}

resource "null_resource" "stack_removal" {
  depends_on = [module.swarm_cluster]
  for_each = local.stacks

  connection {
    user        = self.triggers.user_name
    type        = "ssh"
    host        = self.triggers.host
    private_key = self.triggers.private_key
  }

  provisioner "remote-exec" {
    when = destroy
    inline = ["sudo docker stack rm ${each.key}"]
  }

  triggers = {
    user_name   = module.swarm_cluster.ssh.username
    private_key = module.swarm_cluster.ssh.private_key_pem
    host        = module.swarm_cluster.ssh.ip_addresses.leader
    key         = each.key
  }
}
