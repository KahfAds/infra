terraform {
  backend "azurerm" {
    resource_group_name  = "microk8s-v1-tf"
    storage_account_name = "microk8sterraform"
    container_name       = "terraform"
    key                  = "prod.terraform.tfstate"
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
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
    # helm = {
    #   source = "hashicorp/helm"
    #   version = "2.16.1"
    # }
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

data "azurerm_client_config" "current" {}

provider "azuread" {
  tenant_id = data.azurerm_client_config.current.tenant_id
}

# provider "helm" {
#   kubernetes {
#     config_path = "${path.root}/kubeconfig"
#   }
# }