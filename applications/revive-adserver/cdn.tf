# resource "azurerm_public_ip" "cdn" {
#   name                = "cdn-app-gw-public-ip"
#   location            = azurerm_resource_group.this.location
#   resource_group_name = azurerm_resource_group.this.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }
# #
# resource "azurerm_application_gateway" "cdn" {
#   name                = "cdn"
#   resource_group_name = azurerm_resource_group.this.name
#   location            = azurerm_resource_group.this.location
#   sku                 = "Standard_V2"
#
#   frontend_ip_configuration {
#     name                 = "frontend-ip"
#     public_ip_address_id = azurerm_public_ip.cdn.id
#   }
#
#   backend_address_pool {
#     name = "storage-backend-pool"
#   }
#
#   backend_http_settings {
#     cookie_based_affinity = ""
#     name                  = ""
#     port                  = 0
#     protocol              = ""
#   }
#
#   frontend_port {
#     name = "frontend-port"
#     port = 80
#   }
#
#   http_listener {
#     name                           = "http-listener"
#     frontend_ip_configuration_name = "frontend-ip"
#     frontend_port_name             = "frontend-port"
#     protocol                       = "Http"
#   }
#
#   request_routing_rule {
#     name                       = "default-routing-rule"
#     http_listener_name         = "http-listener"
#     backend_address_pool_name  = "storage-backend-pool"
#     backend_http_settings_name = "http-settings"
#     rule_type                  = "Basic"
#   }
# }
# #
# # # resource "azurerm_frontdoor_profile" "example" {
# # #   name                = "example-frontdoor"
# # #   resource_group_name = azurerm_resource_group.example.name
# # #   location            = "Global"
# # #   sku                 = "Standard_AzureFrontDoor"  # or "Premium_AzureFrontDoor"
# # #
# # #   tags = {
# # #     environment = "Production"
# # #   }
# # # }
# # #
# # # resource "azurerm_frontdoor_endpoint" "example" {
# # #   name                = "example-endpoint"
# # #   resource_group_name = azurerm_resource_group.example.name
# # #   frontdoor_name      = azurerm_frontdoor_profile.example.name
# # #   origin_host_header  = "example-app-gateway.yourdomain.com"  # Use Application Gateway's DNS name
# # #   origin {
# # #     name      = "app-gateway-origin"
# # #     host_name = "example-app-gateway.yourdomain.com"  # Use Application Gateway's DNS name
# # #   }
# # #
# # #   routing_rule {
# # #     name      = "example-routing-rule"
# # #     frontend_endpoints = [azurerm_frontdoor_profile.example.name]
# # #     accepted_protocols = ["Http"]
# # #     patterns_to_match  = ["/*"]
# # #     route_configuration {
# # #       routing_rule {
# # #         name = "default"
# # #         priority = 1
# # #         redirect_configuration {
# # #           redirect_type = "Permanent"
# # #           redirect_protocol = "Http"
# # #         }
# # #       }
# # #     }
# # #   }
# # # }
# # #
# # # resource "azurerm_cdn_profile" "example" {
# # #   name                = "example-cdn-profile"
# # #   resource_group_name = azurerm_resource_group.example.name
# # #   location            = azurerm_resource_group.example.location
# # #   sku                 = "Standard_Akamai"  # or other SKU like "Standard_Microsoft", "Premium_Akamai"
# # #
# # #   tags = {
# # #     environment = "Production"
# # #   }
# # # }
# # #
# # # resource "azurerm_cdn_endpoint" "example" {
# # #   name                = "example-cdn-endpoint"
# # #   resource_group_name = azurerm_resource_group.example.name
# # #   profile_name        = azurerm_cdn_profile.example.name
# # #   location            = azurerm_resource_group.example.location
# # #   origin_host_header  = "example-frontdoor.azurefd.net"  # Use your Front Door hostname
# # #
# # #   origin {
# # #     name      = "frontdoor-origin"
# # #     host_name = "example-frontdoor.azurefd.net"  # Use your Front Door hostname
# # #   }
# # #
# # #   delivery_rule {
# # #     name      = "default-delivery-rule"
# # #     order     = 1
# # #     action {
# # #       name = "UrlRedirect"
# # #       parameters {
# # #         redirect_type = "Found"
# # #         redirect_protocol = "Https"
# # #         redirect_url = "https://example-frontdoor.azurefd.net/{uri}"
# # #       }
# # #     }
# # #   }
# # #
# # #   tags = {
# # #     environment = "Production"
# # #   }
# # # }