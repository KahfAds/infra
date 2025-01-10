terraform {
  backend "azurerm" {
    resource_group_name  = "microk8s-v1-tf"
    storage_account_name = "microk8sterraform"
    container_name       = "terraform"
    key                  = "prod.apps.terraform.tfstate"
  }
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "2.17.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.35.1"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
    config_context = "microk8s"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  config_context = "microk8s"
}