variable "storage_account_name" {}

variable "nfs_endpoint" {}

resource "azurerm_storage_container" "this" {
  name                  = "qrm-logos"
  storage_account_name  = var.storage_account_name
  container_access_type = "private"
}

variable "docker_config_name" {}

output "stack" {
  value = templatefile("${path.module}/docker-compose.yaml", {
    APP_CONFIG_NAME = var.docker_config_name
    NFS_DEVICE = "${var.storage_account_name}/${azurerm_storage_container.this.name}"
    NFS_ENDPOINT = var.nfs_endpoint
  })
}