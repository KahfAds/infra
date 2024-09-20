locals {
  location = "southeastasia"

  volumes = {
    admin-plugins : []
    images : []
    plugins : []
    var : ["cache/dummy.txt", "plugins/DataObjects/dummy.txt", "plugins/recover/dummy.txt"]
  }

  stack = base64encode(templatefile("docker-compose.yml.tpl", {
    ENV                        = "production"
    AZURE_STORAGE_ACCOUNT_HOST = "${azurerm_storage_account.this.name}.${azurerm_private_dns_zone.storage_blob_dns.name}"
    AZURE_STORAGE_ACCOUNT      = azurerm_storage_account.this.name
    volumes = keys(local.volumes)
    SERVER_ADDR = module.swarm_cluster.docker.host
  }))

  docker_network_name = "public"
}

resource "azurerm_resource_group" "this" {
  location = local.location
  name     = "kahf-ads-production"
}

