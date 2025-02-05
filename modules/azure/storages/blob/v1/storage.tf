terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.108.0"
    }
  }
}
variable "resource_group" {
  type = object({
    name = string
    location = string
  })
}

variable "name" {}

resource "azurerm_private_dns_zone" "this" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group.name
}

resource "azurerm_storage_account" "this" {
  account_replication_type      = "LRS"
  account_tier                  = "Standard"
  location                      = var.resource_group.location
  name                          = var.name
  resource_group_name           = var.resource_group.name
  account_kind                  = "StorageV2"
  public_network_access_enabled = true
  enable_https_traffic_only     = false

  static_website {
    index_document = "index.html"
    error_404_document = "404.html"
  }
}

variable "sas_expiry" {
  default = "87658h" # 10year
}

variable "containers" {
  type = map(string) # { name => access_type }
}

resource "azurerm_storage_container" "this" {
  for_each = var.containers
  name                  = each.key
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = each.value
}

output "account" {
  value = azurerm_storage_account.this.name
}

output "primary_access_key" {
  value = azurerm_storage_account.this.primary_access_key
}

output "primary_blob_host" {
  value = azurerm_storage_account.this.primary_blob_host
}

output "id" {
  value = azurerm_storage_account.this.id
}

output "credentials" {
  value = {
    username = module.credentials.client_id
    password = module.credentials.client_secret
    tenant_id = module.credentials.tenant_id
  }
}

module "credentials" {
  source = "../../../ad/service_principal"
  name_prefix = "${var.name}-storage"
  scope_id    = azurerm_storage_account.this.id
  role_definition_name = "Contributor"
}

# data "azurerm_storage_account_sas" "this" {
#   connection_string = azurerm_storage_account.this.primary_connection_string
#   https_only = true
#   expiry            = timeadd(timestamp(), var.sas_expiry)
#   start             = timeadd(timestamp(), "-5m")
#
#   permissions {
#     read    = true
#     write   = true
#     delete  = false
#     list    = false
#     add     = true
#     create  = true
#     update  = false
#     process = false
#     tag     = false
#     filter  = false
#   }
#
#   resource_types {
#     service   = true
#     container = true
#     object    = true
#   }
#
#   services {
#     blob  = true
#     file  = false
#     queue = false
#     table = false
#   }
# }

# output "sas_token" {
#   value = data.azurerm_storage_account_sas.this.sas
# }