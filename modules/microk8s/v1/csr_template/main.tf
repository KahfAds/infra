variable "node" {
  type = object({
    host = string
    user = string
    private_key = string
  })
}

variable "additional_ips" {
  type = list(string)
  default = []
}

variable "additional_domains" {
  type = list(string)
  default = []
}

locals {
  ip_addition_command = [ for idx, ip in var.additional_ips:
    "sed -i 's@#MOREIPS@IP.${99-idx} = ${ip}\\n#MOREIPS\\n@g' /var/snap/microk8s/current/certs/csr.conf.template"
  ]
  ip_removal_command = [ for idx, ip in var.additional_ips:
    "sed -i '/IP.${99-idx} = ${ip}/d' /var/snap/microk8s/current/certs/csr.conf.template"
  ]
}

resource "null_resource" "update_ips" {
  count = length(var.additional_ips)

  # Target a specific master node
  connection {
    type        = "ssh"
    host        = self.triggers.host
    user        = self.triggers.user
    private_key = self.triggers.private_key
  }

  # Add the IP or domain during creation
  provisioner "remote-exec" {
    inline = [
      "sed -i 's@#MOREIPS@IP.${self.triggers.index} = ${self.triggers.ip_address}\\n#MOREIPS\\n@g' /var/snap/microk8s/current/certs/csr.conf.template"
    ]
  }

  # Remove the IP or domain during destruction
  provisioner "remote-exec" {
    when    = destroy
    inline = [
      "sed -i '/IP.${self.triggers.index} = ${self.triggers.ip_address}/d' /var/snap/microk8s/current/certs/csr.conf.template"
    ]
  }

  triggers = {
    ip_address = var.additional_ips[count.index]
    index = 99-count.index
    host        = var.node.host
    user        = var.node.user
    private_key = var.node.private_key
  }
}

resource "null_resource" "update_domains" {
  count = length(var.additional_domains)

  connection {
    type        = "ssh"
    host        = self.triggers.host
    user        = self.triggers.user
    private_key = self.triggers.private_key
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i '/\\[ alt_names \\]/a DNS.${self.triggers.index} = ${self.triggers.domain}' /var/snap/microk8s/current/certs/csr.conf.template"
    ]
  }

  provisioner "remote-exec" {
    when    = destroy
    inline = [
      "sudo sed -i '/DNS.${self.triggers.index} = ${self.triggers.domain}/d' /var/snap/microk8s/current/certs/csr.conf.template"
    ]
  }

  triggers = {
    domain = var.additional_domains[count.index]
    index = 99-count.index
    host        = var.node.host
    user        = var.node.user
    private_key = var.node.private_key
  }
}