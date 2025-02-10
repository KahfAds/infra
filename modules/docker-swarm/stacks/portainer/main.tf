variable "root_domain" {}

variable "storage_account_name" {}

variable "nfs_endpoint" {}

resource "azurerm_storage_container" "this" {
  name                 = "portainer-data"
  storage_account_name = var.storage_account_name
}

output "stack" {
  value = templatefile("${path.module}/docker-compose.yaml", {
    root_domain = var.root_domain
    nfs_endpoint = var.nfs_endpoint
    nfs_device = "${var.storage_account_name}/${azurerm_storage_container.this.name}"
  })
}