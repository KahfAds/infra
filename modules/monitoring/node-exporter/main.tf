terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
  }
}

resource "null_resource" "install" {

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y wget",
      "wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz",
      "tar xvf node_exporter-1.8.2.linux-amd64.tar.gz",
      "cd node_exporter-1.8.2.linux-amd64",
      "sudo mv node_exporter /usr/local/bin/",
      "sudo useradd -rs /bin/false node_exporter",
      "sudo mkdir /etc/node_exporter",
      "sudo chown node_exporter:node_exporter /etc/node_exporter",
      "sudo touch /etc/node_exporter/node_exporter.yml"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh.username
      private_key = var.ssh.private_key_pem
      host        = var.ssh.ip_address
    }
  }
}

data "template_file" "install" {
  template = <<-EOT

  EOT
}

data "template_file" "service" {
  template = <<-EOT
  [Unit]
  Description=Prometheus Node Exporter
  Documentation=https://prometheus.io/docs/node_exporter/

  [Service]
  User=node_exporter
  ExecStart=/usr/local/bin/node_exporter ${join(" ", formatlist("%s=%s", keys(var.collectors), values(var.collectors)))}
  Restart=always

  [Install]
  WantedBy=multi-user.target
  EOT
}

resource "null_resource" "configure" {
  depends_on = [null_resource.install]

  provisioner "remote-exec" {
    inline = [
      "echo '${data.template_file.service.rendered}' | sudo tee /etc/systemd/system/node_exporter.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl restart node_exporter"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh.username
      private_key = var.ssh.private_key_pem
      host        = var.ssh.ip_address
    }
  }
}

output "service" {
  value = data.template_file.service.rendered
}