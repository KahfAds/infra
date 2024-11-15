resource "random_password" "proxy" {
  length           = 12
  special          = true
  override_special = "_%@"
}

locals {
  stack_proxy = base64encode(templatefile("${path.module}/stacks/proxy.yaml", {
    password = random_password.proxy.bcrypt_hash
    network_name               = "proxy"
    NFS_DEVICE = "${module.nfs.account}/${azurerm_storage_container.tarefik_tls.name}"
    NFS_ENDPOINT = module.nfs.endpoint
  }))
}

resource "azurerm_storage_container" "tarefik_tls" {
  name                 = "tarefik-tls"
  storage_account_name = module.nfs.account
}
