locals {
  location = "southeastasia"

  volumes = {
    admin-plugins : []
    images : []
    plugins : []
    var : ["cache/dummy.txt", "plugins/DataObjects/dummy.txt", "plugins/recover/dummy.txt"]
  }

  uploads = {
    for k, v in flatten([for key, paths in local.volumes : [for path in paths : { path = path, key = key }]]) :
    v.path => v.key
  }

  stack = base64encode(templatefile("docker-compose.yml.tpl", {
    DB_HOST                    = azurerm_private_dns_zone_virtual_network_link.database.name
    DB_PORT                    = 5432
    DB_NAME                    = azurerm_postgresql_flexible_server_database.revive_ad_server.name
    DB_USERNAME                = local.database_user
    DB_PASSWORD                = random_password.database.result
    ENV                        = "production"
    AZURE_STORAGE_ACCOUNT_HOST = "${azurerm_storage_account.this.name}.${azurerm_private_dns_zone.storage_blob_dns.name}"
    AZURE_STORAGE_ACCOUNT      = azurerm_storage_account.this.name
    volumes = keys(local.volumes)
    SERVER_IP = module.swarm_cluster.docker.host
  }))

  docker_network_name = "public"
}

resource "azurerm_resource_group" "this" {
  location = local.location
  name     = "kahf-ads-production"
}

