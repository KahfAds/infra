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

locals {
  workdir = "/opt/goauthentik"
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

resource "null_resource" "setup_docker" {
  connection {
    host        = var.ssh.host
    user        = var.ssh.user
    private_key = var.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "if ! command -v docker &> /dev/null; then curl -fsSL https://get.docker.com | sudo bash; fi",
      "sudo usermod -aG docker ${var.ssh.user}",
      "if ! command -v docker-compose &> /dev/null; then sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose; fi",
      "sudo mkdir -p ${local.workdir}",
      "sudo chown -R $USER ${local.workdir}/"
    ]
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
  }
}

resource "null_resource" "setup" {
  connection {
    host        = var.ssh.host
    user        = var.ssh.user
    private_key = var.ssh.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "if ! command -v docker &> /dev/null; then curl -fsSL https://get.docker.com | sudo bash; fi",
      "sudo usermod -aG docker ${var.ssh.user}",
      "if ! command -v docker-compose &> /dev/null; then sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose; fi",
      "sudo mkdir -p ${local.workdir}",
      "sudo chown -R $USER ${local.workdir}/"
    ]
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


