terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }
}
resource "random_password" "database" {
  length = 12
  special = false
}

resource "random_password" "authentik_secret_key" {
  length  = 50
  special = true
}

resource "random_password" "authentik_bootstrap_token" {
  length  = 50
  special = false
}

resource "random_password" "authentik_bootstrap_password" {
  length = 12
  special = true
}

locals {
  workdir = "/opt/goauthentik"
}

resource "null_resource" "setup" {

  connection {
    host        = var.ssh.host
    user        = var.ssh.user
    private_key = var.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p ${local.workdir}",
      "sudo chown -R $USER ${local.workdir}/"
    ]
  }

  triggers = {
    host        = var.ssh.host
    user        = var.ssh.user
    private_key = var.ssh.private_key_pem
  }
}

resource "null_resource" "deploy" {
  connection {
    host        = var.ssh.host
    user        = var.ssh.user
    private_key = var.ssh.private_key_pem
  }

  provisioner "file" {
    destination = "${local.workdir}/docker-compose.yml"
    content     = templatefile("${path.module}/docker-compose.yml", {
      letsencrypt_email = var.letsencrypt_email
      pg_password = random_password.database.result
      authentik_domain = var.authentik_domain
      authentik_version = var.authentik_version
      authentik_secret_key = random_password.authentik_secret_key.result
      authentik_bootstrap_token = random_password.authentik_bootstrap_token.result
      authentik_bootstrap_password = random_password.authentik_bootstrap_password.result
      authentik_bootstrap_email = var.admin_email
    })
  }

  provisioner "remote-exec" {
    inline = [
      "cd ${local.workdir} && docker compose up -d"
    ]
  }

  triggers = {
    host        = var.ssh.host
    user        = var.ssh.user
    private_key = var.ssh.private_key_pem
    docker_compose_md5 = filemd5("${path.module}/docker-compose.yml")
  }
}

output "secret_key" {
  value = random_password.authentik_secret_key.result
  sensitive = true
}

output "token" {
  value = random_password.authentik_bootstrap_token.result
  sensitive = true
}

output "password" {
  value = random_password.authentik_bootstrap_password.result
}


