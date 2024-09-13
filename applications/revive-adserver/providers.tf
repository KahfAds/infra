terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.116.0"
    }
    ssh = {
      source = "loafoe/ssh"
      version = "2.7.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "0a9b31f1-58f4-49ec-b5ab-775df1a278e5"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

data "azurerm_client_config" "current" {
  
}