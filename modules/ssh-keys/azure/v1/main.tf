resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "this" {
  filename = pathexpand("~/.ssh/${azurerm_ssh_public_key.this.name}.pem")
  file_permission = "600"
  directory_permission = "700"
  content = tls_private_key.this.private_key_pem
}

resource "azurerm_ssh_public_key" "this" {
  name                = "${var.name_prefix}-ssh-key"
  resource_group_name = var.resource_group_name
  location            = var.location
  public_key          = tls_private_key.this.public_key_openssh
}