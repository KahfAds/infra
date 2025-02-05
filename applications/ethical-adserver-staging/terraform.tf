terraform {
  backend "azurerm" {
    resource_group_name  = "kahfads-common"
    storage_account_name = "adsterraformstates"
    container_name       = "staging"
    key                  = "terraform.tfstate"
  }
  required_providers {
    azapi = {
      source = "azure/azapi"
      version = "2.1.0"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.108.0"
    }
    ssh = {
      source = "loafoe/ssh"
      version = "2.7.0"
    }
    docker = {
      source = "kreuzwerker/docker"
      version = "3.0.2"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "4.0.6"
    }
  }
}

provider "azurerm" {
  subscription_id = "b172e3c9-415f-4e32-90bd-ee239af87844"
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

data "azurerm_client_config" "current" {}

provider "azuread" {
  tenant_id = data.azurerm_client_config.current.tenant_id
}