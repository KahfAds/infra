locals {
  location = "southeastasia"

  volumes = {
    admin-plugins : []
    images : []
    plugins : []
    var : ["cache/dummy.txt", "plugins/DataObjects/dummy.txt", "plugins/recover/dummy.txt"],
    traefik : ["config/dummy.txt", "tls/dummy.txt"]
  }

  stack_revive_ad_server = base64encode(templatefile("${path.module}/stacks/revive-adserver.yml.tpl", {
    ENV                        = "production"

    network_name               = local.proxy_network_name
    AZURE_STORAGE_ACCOUNT_HOST = "${azurerm_storage_account.this.name}.${azurerm_private_dns_zone.storage_blob_dns.name}"
    AZURE_STORAGE_ACCOUNT      = azurerm_storage_account.this.name
    volumes = keys(local.volumes)
  }))

  proxy_network_name = "proxy"
}

resource "azurerm_resource_group" "this" {
  location = local.location
  name     = "kahf-ads-production"
}

