variable "ssh" {
  type = object({
    user       = string
    private_key_pem = string
    host      = string
  })
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
      "if ! command -v docker-compose &> /dev/null; then sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose; fi"
    ]
  }

  triggers = {
    host        = var.ssh.host
    user        = var.ssh.user
    private_key = var.ssh.private_key_pem
  }
}