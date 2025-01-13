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
    external = {
      source  = "hashicorp/external"
      version = "2.3.3"
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
      "mkdir -p ~/.kube",
      "sudo chown -R ${local.nodes[count.index].user} ~/.kube",
      "sudo microk8s status --wait-ready",
      "alias kubectl='microk8s kubectl'",
      "git config --global --add safe.directory /snap/microk8s/current/addons/community/.git",
      "sudo microk8s enable community",
      "sudo microk8s enable nfs"
    ]
  }
}

module "csr_template" {
  count = length(local.nodes)
  depends_on = [null_resource.install]
  source = "./csr_template"
  additional_domains = var.additional_cluster_domains
  additional_ips = concat(var.additional_cluster_ip_addresses, [var.initiator_node.private_ip, var.initiator_node.host])
  node = {
    host = local.nodes[count.index].host
    user = local.nodes[count.index].user
    private_key = local.nodes[count.index].private_key
  }
}

resource "null_resource" "setup_initiator_node" {
  depends_on = [module.csr_template]

  connection {
    type        = "ssh"
    host        = var.initiator_node.host
    private_key = var.initiator_node.private_key
    user        = var.initiator_node.user
  }

  provisioner "remote-exec" {
    inline = [
      "microk8s.kubectl label node ${var.initiator_node.hostname} node-role.kubernetes.io/control-plane=\"\"",
      "microk8s enable dashboard",
      "microk8s enable dns",
      "microk8s enable observability --kube-prometheus-stack-version=67.9.0 --loki-stack-version=2.10.2 --tempo-version=1.16.0",
      "microk8s enable cert-manager",
      "microk8s enable hostpath-storage",
      "microk8s enable helm",
      "microk8s enable helm3",
      "microk8s.kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.1.1/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml",
      "microk8s.kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.1.1/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml",
      "microk8s.kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.1.1/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml",
      "microk8s.kubectl apply -n kube-system -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.1.1/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml",
      "microk8s.kubectl apply -n kube-system -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.1.1/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml",
      "microk8s.helm3 repo add traefik https://traefik.github.io/charts",
      "microk8s.helm3 repo update",
      "microk8s.helm3 install traefik traefik/traefik --create-namespace --namespace traefik --set ports.traefik.expose.default=true --set ports.traefik.nodePort=${var.ingress.dashboard_port} --set ports.web.nodePort=${var.ingress.web_port} --set ports.websecure.nodePort=${var.ingress.websecure_port} --set ingressRoute.dashboard.enabled=true --set service.type=NodePort --version 33.2.0",
      "sudo microk8s status --wait-ready"
    ]
  }
}

data "external" "kubeconfig" {
  depends_on = [null_resource.setup_initiator_node]
  program = [
    "bash",
    "${path.module}/scripts/query-kubeconfig.sh",
    base64encode(var.initiator_node.private_key),
    var.initiator_node.user,
    var.initiator_node.host
  ]
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
  depends_on = [null_resource.setup_initiator_node]
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
      "fi",
      "sudo microk8s.kubectl label node ${var.master_nodes[count.index].hostname} node-role.kubernetes.io/control-plane=\"\"",
    ]
  }
}

resource "null_resource" "remove_master_node_from_initiator" {
  count = length(var.master_nodes)

  connection {
    type        = "ssh"
    host        = self.triggers.host
    user        = self.triggers.user
    private_key = self.triggers.private_key
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "sudo microk8s remove-node ${self.triggers.hostname} --force"
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
  depends_on = [null_resource.join_master_nodes]
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

resource "null_resource" "remove_worker_node_from_initiator" {
  count = length(var.worker_nodes)

  connection {
    type        = "ssh"
    host        = self.triggers.host
    user        = self.triggers.user
    private_key = self.triggers.private_key
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "sudo microk8s remove-node ${self.triggers.hostname} --force"
    ]
  }

  triggers = {
    host        = var.initiator_node.host
    private_key = var.initiator_node.private_key
    user        = var.initiator_node.user
    hostname    = var.worker_nodes[count.index].hostname
  }
}
