terraform {
  backend "azurerm" {
    resource_group_name  = "ad-server-01-terraform"
    storage_account_name = "terraform500"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}