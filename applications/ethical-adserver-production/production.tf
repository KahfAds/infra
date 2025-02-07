terraform {
  backend "azurerm" {
    resource_group_name  = "kahfads-common"
    storage_account_name = "adsterraformstates"
    container_name       = "production"
    key                  = "terraform.tfstate"
  }
}

locals {
  root_domain = "kahfads.com"
}