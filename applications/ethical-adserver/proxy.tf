resource "random_password" "proxy" {
  length           = 12
  special          = true
  override_special = "_%@"
}

locals {
  proxy_network_name = "proxy"
  stack_proxy = base64encode(templatefile("${path.module}/stacks/proxy.yaml.tpl", {
    password = random_password.proxy.bcrypt_hash
    network_name               = "proxy"
  }))
}
