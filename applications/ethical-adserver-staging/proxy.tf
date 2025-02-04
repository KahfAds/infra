resource "random_password" "proxy" {
  length           = 12
  special          = true
  override_special = "_%@"
}

locals {
  stack_proxy = base64encode(templatefile("${path.module}/stacks/proxy/docker-compose.yaml", {
    password = base64encode(random_password.proxy.bcrypt_hash)
    network_name               = "proxy"
    NFS_DEVICE = "${module.nfs.account}/${azurerm_storage_container.tarefik_tls.name}"
    NFS_ENDPOINT = module.nfs.endpoint
    GOOGLE_OIDC_CLIENT_ID = var.proxy_dashboard.oidc_client_id
    GOOGLE_OIDC_CLIENT_SECRET = var.proxy_dashboard.oidc_client_secret
    root_domain = local.root_domain
    acme_email = "mazharul+30@kahf.co"
  }))
}

resource "azurerm_storage_container" "tarefik_tls" {
  name                 = "tarefik-tls"
  storage_account_name = module.nfs.account
}
