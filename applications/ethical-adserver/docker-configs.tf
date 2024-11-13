locals {
  docker_configs = {
    loki = {
      name = "loki"
      content = file("${path.module}/stacks/logging/loki.yaml")
    }
    promtail = {
      name = "promtail"
      content = file("${path.module}/stacks/logging/promtail.yaml")
    },
    qrc = {
      name = "qrc_app"
      content = templatefile("${path.module}/stacks/qrc/.env", {
        APP_ENV = "production"
        APP_KEY = var.qrc.app_key
        APP_DEBUG = true
        APP_URL = var.qrc.app_url

        DB_CONNECTION = "postgresql"
        DB_HOST = azurerm_postgresql_flexible_server.this.fqdn
        DB_PORT = 5432
        DB_DATABASE = azurerm_postgresql_flexible_server_database.qr_code_management.name
        DB_USERNAME = azurerm_postgresql_flexible_server.this.administrator_login
        DB_PASSWORD = azurerm_postgresql_flexible_server.this.administrator_password
        MIX_PUSHER_APP_KEY = "xxxx"
        MIX_PUSHER_APP_CLUSTER = "xxx"
      })
    }
  }
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
