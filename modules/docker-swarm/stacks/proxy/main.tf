variable "static_config_name" {}

variable "dynamic_config_name" {}

variable "root_domain" {}

variable "nfs_endpoint" {}

variable "nfs_device" {}

variable "network_name" {}

output "stack" {
  value = templatefile("${path.module}/docker-compose.yaml", {
    dynamic_config_name = var.dynamic_config_name
    static_config_name = var.static_config_name
    root_domain = var.root_domain
    nfs_endpoint = var.nfs_endpoint
    nfs_device = var.nfs_device
    network_name = var.network_name
    replicas = var.replicas
  })
}

variable "replicas" {
  default = 1
  type = number
}