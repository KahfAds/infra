resource "local_file" "docker_ca" {
  count = var.create_docker_context ? 1 : 0

  filename = "${path.root}/certs/.docker/ca.pem"
  content = tls_self_signed_cert.ca_cert.cert_pem
}

resource "local_file" "docker_cert" {
  count = var.create_docker_context ? 1 : 0

  filename = "${path.root}/certs/.docker/cert.pem"
  content = tls_locally_signed_cert.client_cert.cert_pem
}

resource "local_file" "docker_key" {
  count = var.create_docker_context ? 1 : 0

  filename = "${path.root}/certs/.docker/key.pem"
  content = tls_private_key.client_key.private_key_pem
}

resource "null_resource" "docker_context" {
  count = var.create_docker_context ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
docker context create ${var.name_prefix} \
  --docker "host=tcp://${azurerm_public_ip.primary.ip_address}:2376" \
  --docker "ca=${abspath(local_file.docker_ca[0].filename)}" \
  --docker "cert=${abspath(local_file.docker_cert[0].filename)}" \
  --docker "key=${abspath(local_file.docker_key[0].filename)}"
EOT
  }

  triggers = {
    ip_address = azurerm_public_ip.primary.ip_address
  }
}
