resource "null_resource" "install" {
  count = length(local.nodes)
  connection {
    type        = "ssh"
    host        = local.nodes[count.index].host
    private_key = local.nodes[count.index].private_key
    user        = local.nodes[count.index].user
  }

  provisioner "file" {
    source = templatefile("${path.module}/scripts/install.sh", {
      USER = local.nodes[count.index].user
      microk8s_channel = var.microk8s_channel
    })
    destination = "/tmp/install-cluster.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install-cluster.sh",
      "/tmp/install-cluster.sh"
    ]
  }
}
