terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
  }
}

data "template_file" "install_script" {
  template = file("${path.module}/scripts/install.sh.tmpl")
  vars = {
    MICROK8S_CHANNEL = var.install_channel
  }
}

resource "local_file" "install_script" {
  filename = "${path.module}/scripts/install.sh"
  content = data.template_file.install_script.rendered
}

resource "null_resource" "install" {
  count = length(local.nodes)
  depends_on = [local_file.install_script]
  connection {
    type        = "ssh"
    host        = local.nodes[count.index].host
    private_key = local.nodes[count.index].private_key
    user        = local.nodes[count.index].user
  }

  provisioner "file" {
    source = local_file.install_script.filename
    destination = "/tmp/install-cluster.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install-cluster.sh",
      "/tmp/install-cluster.sh"
    ]
  }
}
