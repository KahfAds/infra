data "terraform_remote_state" "micro_k8s_v1" {
  backend = "azurerm"

  config = {
    resource_group_name  = "microk8s-v1-tf"
    storage_account_name = "microk8sterraform"
    container_name       = "terraform"
    key                  = "prod.terraform.tfstate"
  }
}
