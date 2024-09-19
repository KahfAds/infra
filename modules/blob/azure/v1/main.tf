variable "resource_group" {
  type = object({
    name = string
    location = string
  })
}

variable "name-prefix" {}

resource "azurerm_storage_account" "nfs_storage_account" {
  name                     = "${var.name-prefix}storageaccount" # Must be globally unique
  resource_group_name       = var.resource_group.name
  location                  = var.resource_group.location
  account_tier              = "Premium"
  account_replication_type  = "LRS" # Premium Block Blob accounts only support LRS replication
  account_kind              = "BlockBlobStorage" # Required for NFSv3 support

  blob_properties {
    # Enable NFSv3 access
    container_delete_retention_policy {
      days = 7 # Optional, retention period
    }

    default_service_version = "2020-06-12" # Minimum version required for NFS
  }

  tags = {
    environment = "dev"
  }
}