output "stack" {
  value = templatefile("${path.module}/docker-compose.yaml", {
    NFS_ENDPOINT = var.nfs_endpoint
    NFS_DEVICE = "${var.storage_account_name}/${azurerm_storage_container.this.name}"
    GRAFANA_USER     = "admin"
    GRAFANA_PASSWORD = "4U0T1&BrlWAL"
    PROMETHEUS_CONFIG_NAME = var.prometheus_config_name
    LOKI_CONFIG_NAME = var.loki_config_name
    PROMTAIL_CONFIG_NAME = var.promtail_config_name
    LOKI_DISK_MOUNT_POINT = var.loki_disk_mount_point
    root_domain = var.root_domain
    databases = var.databases
  })
}

variable "storage_account_name" {}

variable "nfs_endpoint" {}

variable "prometheus_config_name" {}

variable "loki_config_name" {}

variable "promtail_config_name" {}

variable "loki_disk_mount_point" {}

variable "root_domain" {}

resource "azurerm_storage_container" "this" {
  name                 = "grafana-data"
  storage_account_name = var.storage_account_name
}

variable "databases" {
  type = map(string)
  default = {}
}