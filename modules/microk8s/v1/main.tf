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
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
  }
}

resource "null_resource" "install" {
  count = length(local.nodes)
  connection {
    type        = "ssh"
    host        = local.nodes[count.index].host
    private_key = local.nodes[count.index].private_key
    user        = local.nodes[count.index].user
  }

  provisioner "remote-exec" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo sed -i \"s/#\\$nrconf{kernelhints} = -1;/\\$nrconf{kernelhints} = -1;/g\" /etc/needrestart/needrestart.conf",
      "sudo apt update",
      "sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y",
      "sudo apt install -y snapd",
      "sudo apt install -y nfs-kernel-server bridge-utils open-iscsi",
      "sudo systemctl start iscsid",
      "sudo snap install microk8s --channel=${var.install_channel} --classic"
    ]
  }
}

resource "random_id" "cluster_token" {
  byte_length = 16
}

resource "null_resource" "setup_node_sudo" {
  depends_on = [null_resource.install]

  count = length(local.nodes)

  triggers = {
    rerun = random_id.cluster_token.hex
  }

  connection {
    type        = "ssh"
    host        = local.nodes[count.index].host
    private_key = local.nodes[count.index].private_key
    user        = local.nodes[count.index].user
  }

  provisioner "remote-exec" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo usermod -a -G microk8s ${local.nodes[count.index].user}",
      "sudo chown -f -R ${local.nodes[count.index].user} ~/.kube",
      "microk8s status --wait-ready",
      "alias kubectl='microk8s kubectl'",
      "git config --global --add safe.directory /snap/microk8s/current/addons/community/.git",
      "microk8s enable traefik",
      "microk8s enable community",
      "microk8s enable dns",
      "microk8s enable prometheus",
      "microk8s enable cert-manager",
      "microk8s enable hostpath-storage",
      "microk8s enable helm ",
      "microk8s enable helm3"
    ]
  }
}


#
resource "null_resource" "initiate_add_node" {
  connection {
    type        = "ssh"
    host        = var.initiator_node.host
    private_key = var.initiator_node.private_key
    user        = var.initiator_node.user
  }

  provisioner "remote-exec" {
    inline = [
      "echo \"adding main node ${var.initiator_node.host} dns to CSR.\"",
      "sed -i 's@#MOREIPS@IP.99 = ${var.initiator_node.host}\\n#MOREIPS\\n@g' /var/snap/microk8s/current/certs/csr.conf.template",
      "echo 'done.'",
      "mkdir -p /tmp/config",
      "sleep 30",
      "sudo microk8s add-node --token ${random_id.cluster_token.hex} --token-ttl ${var.cluster_token_ttl_seconds}",
      "sudo microk8s config -l > /tmp/config/client.config",
      "echo \"updating kubeconfig\"",
      "sed -i 's/127.0.0.1/${var.initiator_node.host}/g' /tmp/config/client.config",
      "chmod o+r /tmp/config/client.config"
    ]
  }
}

resource "null_resource" "get_kubeconfig" {
  depends_on = [null_resource.initiate_add_node]

  provisioner "local-exec" {
    command = <<EOT
      tmp_key=$(mktemp) && \
      echo "${var.initiator_node.private_key}" > $tmp_key && \
      chmod 600 $tmp_key && \
      scp -i $tmp_key ${var.initiator_node.user}@${var.initiator_node.host}:/tmp/config/client.config /tmp/client.config && \
      rm -f $tmp_key
    EOT
  }
}
