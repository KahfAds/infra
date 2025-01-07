locals {
  nodes = concat([var.initiator_node], var.master_nodes, var.worker_nodes)
  non_initiator_nodes = concat(var.master_nodes, var.worker_nodes)

  update_csr = [
    "echo \"adding initiator node IPs to CSR.\"",
    "sed -i 's@#MOREIPS@IP.98 = ${var.initiator_node.private_ip}\\n#MOREIPS\\n@g' /var/snap/microk8s/current/certs/csr.conf.template",
    "sed -i 's@#MOREIPS@IP.99 = ${var.initiator_node.host}\\n#MOREIPS\\n@g' /var/snap/microk8s/current/certs/csr.conf.template",
    "echo 'done.'"
  ]

  ingress = {
    web_port = 30080
    websecure_port = 30443
    dashboard_port = 30880
  }
}