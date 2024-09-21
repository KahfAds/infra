resource "random_password" "proxy" {
  length           = 12
  special          = true
  override_special = "_%@"
}

locals {
  stack_proxy = base64encode(templatefile("${path.module}/stacks/proxy.yaml.tpl", {
    password = random_password.proxy.bcrypt_hash

    network_name               = local.docker_network_name
    AZURE_STORAGE_ACCOUNT_HOST = "${azurerm_storage_account.this.name}.${azurerm_private_dns_zone.storage_blob_dns.name}"
    AZURE_STORAGE_ACCOUNT      = azurerm_storage_account.this.name
    volumes = keys(local.volumes)
  }))
}
