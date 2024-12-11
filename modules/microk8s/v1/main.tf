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
      "sudo DEBIAN_FRONTEND=noninteractive apt install -y snapd",
      "sudo DEBIAN_FRONTEND=noninteractive apt install -y nfs-common bridge-utils open-iscsi",
      "sudo systemctl start iscsid",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y debconf-utils",
      "echo '* libraries/restart-without-asking boolean true' | sudo debconf-set-selections",
      "sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y",
      "sudo snap install microk8s --channel=${var.install_channel} --classic",
      "sudo usermod -a -G microk8s ${local.nodes[count.index].user}",
      "sudo chown -R ${local.nodes[count.index].user} ~/.kube",
      "microk8s status --wait-ready",
      "alias kubectl='microk8s kubectl'",
      "echo \"adding initiator node IPs to CSR.\"",
      "sed -i 's@#MOREIPS@IP.98 = ${var.initiator_node.private_ip}\\n#MOREIPS\\n@g' /var/snap/microk8s/current/certs/csr.conf.template",
      "sed -i 's@#MOREIPS@IP.99 = ${var.initiator_node.host}\\n#MOREIPS\\n@g' /var/snap/microk8s/current/certs/csr.conf.template",
      "echo 'done.'",
      "git config --global --add safe.directory /snap/microk8s/current/addons/community/.git",
      "microk8s enable community",
      "microk8s enable nfs",
    ]
  }
}

resource "null_resource" "setup_initiator_node" {
  depends_on = [null_resource.install]

  connection {
    type        = "ssh"
    host        = var.initiator_node.host
    private_key = var.initiator_node.private_key
    user        = var.initiator_node.user
  }

  provisioner "remote-exec" {
    inline = [
      "microk8s enable traefik",
      "microk8s enable dashboard",
      "microk8s enable dns",
      "microk8s enable prometheus",
      "microk8s enable cert-manager",
      "microk8s enable hostpath-storage",
      "microk8s enable helm",
      "microk8s enable helm3",
      "mkdir -p /tmp/config",
      "sudo microk8s config -l > /tmp/config/client.config",
      "echo \"updating kubeconfig\"",
      "sed -i 's/127.0.0.1/${var.initiator_node.host}/g' /tmp/config/client.config",
      "chmod o+r /tmp/config/client.config"
    ]
  }
}

resource "null_resource" "get_kubeconfig" {
  depends_on = [null_resource.setup_initiator_node]

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

data "external" "add_node_token" {
  depends_on = [null_resource.setup_initiator_node]
  program = [
    "bash",
    "${path.module}/scripts/query-token.sh",
    base64encode(var.initiator_node.private_key),
    var.initiator_node.user,
    var.initiator_node.host
  ]
}

resource "null_resource" "join_master_nodes" {
  depends_on = [null_resource.get_kubeconfig]
  count = length(var.master_nodes)

  connection {
    type        = "ssh"
    host        = var.master_nodes[count.index].host
    private_key = var.master_nodes[count.index].private_key
    user        = var.master_nodes[count.index].user
  }

  provisioner "remote-exec" {
    inline = [
      "microk8s status --wait-ready",
      "if microk8s status | grep \"datastore master nodes: 127.0.0.1:19001\" > /dev/null 2>&1; then",
      "sudo microk8s join ${var.initiator_node.private_ip}:25000/${data.external.add_node_token.result.token}",
      "microk8s status --wait-ready",
      "else",
      "echo \"Join process already done. Nothing to do\"",
      "fi"
    ]
  }
}

resource "null_resource" "remove_master_node_from_itself" {
  depends_on = [null_resource.get_kubeconfig, null_resource.remove_master_node_from_initiator]
  count = length(var.master_nodes)

  connection {
    type        = "ssh"
    host        = self.triggers.user
    user        = self.triggers.host
    private_key = self.triggers.private_key
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "microk8s leave"
    ]
  }

  triggers = {
    host        = var.master_nodes[count.index].host
    private_key = var.master_nodes[count.index].private_key
    user        = var.master_nodes[count.index].user
  }
}

resource "null_resource" "remove_master_node_from_initiator" {
  count = length(var.master_nodes)

  connection {
    type        = "ssh"
    host        = self.triggers.user
    user        = self.triggers.host
    private_key = self.triggers.private_key
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "microk8s remove-node ${self.triggers.hostname}"
    ]
  }

  triggers = {
    host        = var.initiator_node.host
    private_key = var.initiator_node.private_key
    user        = var.initiator_node.user
    hostname    = var.master_nodes[count.index].hostname
  }
}

resource "null_resource" "join_worker_nodes" {
  depends_on = [null_resource.get_kubeconfig]
  count = length(var.worker_nodes)

  connection {
    type        = "ssh"
    host        = var.worker_nodes[count.index].host
    private_key = var.worker_nodes[count.index].private_key
    user        = var.worker_nodes[count.index].user
  }

  provisioner "remote-exec" {
    inline = [
      "microk8s status --wait-ready",
      "if microk8s status | grep \"datastore master nodes: 127.0.0.1:19001\" > /dev/null 2>&1; then",
      "sudo microk8s join ${var.initiator_node.private_ip}:25000/${data.external.add_node_token.result.token} --worker",
      "microk8s status --wait-ready",
      "else",
      "echo \"Join process already done. Nothing to do\"",
      "fi"
    ]
  }
}

resource "null_resource" "remove_worker_node_from_itself" {
  depends_on = [null_resource.get_kubeconfig]
  count = length(var.worker_nodes)

  connection {
    type        = "ssh"
    host        = self.triggers.user
    user        = self.triggers.host
    private_key = self.triggers.private_key
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "microk8s leave"
    ]
  }

  triggers = {
    host        = var.worker_nodes[count.index].host
    private_key = var.worker_nodes[count.index].private_key
    user        = var.worker_nodes[count.index].user
    hostname    = var.worker_nodes[count.index].hostname
  }
}

resource "null_resource" "remove_worker_node_from_initiator" {
  depends_on = [null_resource.remove_worker_node_from_itself]
  count = length(var.worker_nodes)

  connection {
    type        = "ssh"
    host        = self.triggers.user
    user        = self.triggers.host
    private_key = self.triggers.private_key
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "microk8s remove-node ${self.triggers.hostname}"
    ]
  }

  triggers = {
    host        = var.initiator_node.host
    private_key = var.initiator_node.private_key
    user        = var.initiator_node.user
    hostname    = var.worker_nodes[count.index].hostname
  }
}
