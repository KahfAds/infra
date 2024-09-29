locals {
  location = "southeastasia"

#   volumes = {
#     admin-plugins : []
#     images : []
#     plugins : []
#     var : ["cache/dummy.txt", "plugins/DataObjects/dummy.txt", "plugins/recover/dummy.txt"],
#     traefik : ["config/dummy.txt", "tls/dummy.txt"]
#   }
#
#   stack_revive_ad_server = base64encode(templatefile("${path.module}/stacks/revive-adserver.yml.tpl", {
#     ENV                        = local.env
#     network_name               = local.proxy_network_name
#   }))

}

resource "azurerm_resource_group" "this" {
  location = local.location
  name     = "kahf-ads-${local.env}"
}

