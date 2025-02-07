locals {
  root_domain = "${var.env}.kahfads.com"
}

terraform {
  backend "azurerm" {
    resource_group_name  = "kahfads-common"
    storage_account_name = "adsterraformstates"
    container_name       = "staging"
    key                  = "terraform.tfstate"
  }
}