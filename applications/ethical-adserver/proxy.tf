resource "random_password" "proxy" {
  length           = 12
  special          = true
  override_special = "_%@"
}

locals {
  stack_proxy = base64encode(templatefile("${path.module}/stacks/proxy.yaml", {
    password = random_password.proxy.bcrypt_hash
    network_name               = "proxy"
  }))
}
