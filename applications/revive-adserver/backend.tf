# module "backend" {
#   source = "./backend"
#   database = {
#     host = azurerm_private_dns_zone_virtual_network_link.database.name
#   }
#   docker = {}
#   resource_group = {}
# }