# resource "random_id" "cluster_token" {
#   byte_length = 16
# }
#
# resource "null_resource" "set_node_sudo" {
#   count = length(local.nodes)
#   triggers = {
#     rerun = random_id.cluster_token.hex
#   }
#   connection {
#     type        = "ssh"
#     host        = local.nodes[count.index].host
#     private_key = local.nodes[count.index].private_key
#     user        = local.nodes[count.index].user
#   }
#
#   provisioner "remote-exec" {
#     inline = [
#       "sudo usermod -a -G microk8s ${local.nodes[count.index].user}",
#       "sudo chown -f -R ${local.nodes[count.index].user} ~/.kube",
#       "su - ${local.nodes[count.index].user}",
#       "microk8s status --wait-ready",
#       "alias kubectl='microk8s kubectl'",
#       "microk8s enable community dns prometheus cert-manager hostpath-storage helm helm3"
#     ]
#   }
# }
#
# # setup_token must be done only on the main node.
# # Then prepare for the join nodes by creating the sequence token in /tmp/current_joining_node.txt
# resource "null_resource" "setup_tokens" {
#   depends_on = [null_resource.set_node_sudo]
#   count = length(local.nodes)
#   triggers = {
#     rerun = random_id.cluster_token.hex
#   }
#   connection {
#     type = "ssh"
#     host = local.nodes[count.index].host
#     user = local.nodes[count.index].user
#     timeout = "15m"
#   }
#
#   provisioner "local-exec" {
#     interpreter = ["bash", "-c"]
#     command = "echo \"1\" > /tmp/current_joining_node.txt"
#   }
#
#   provisioner "file" {
#     content = templatefile("${path.module}/templates/add-node.sh",
#       {
#         main_node                 = var.initiator_node.host
#         cluster_token             = random_id.cluster_token.hex
#         cluster_token_ttl_seconds = var.cluster_token_ttl_seconds
#       })
#     destination = "/tmp/add-node.sh"
#   }
#
#   provisioner "remote-exec" {
#     inline = [
#       "sh /tmp/add-node.sh",
#     ]
#   }
# }
#
# # Joining nodes must be done in sequence.
# # The first and last provisioners is to make sure that joining nodes is not done in parallel.
# resource "null_resource" "join_nodes" {
#   count = length(local.nodes) - 1 < 1 ? 0 : length(local.nodes) - 1
#
#   depends_on = [null_resource.set_node_sudo, null_resource.setup_tokens]
#
#   triggers = {
#     rerun = random_id.cluster_token.hex
#   }
#
#   connection {
#     type        = "ssh"
#     host        = local.nodes[count.index].host
#     private_key = local.nodes[count.index].private_key
#     user        = local.nodes[count.index].user
#   }
#
#   provisioner "local-exec" {
#     interpreter = ["bash", "-c"]
#     command = "while [[ $(cat /tmp/current_joining_node.txt) != \"${count.index +1}\" ]]; do echo \"${count.index +1} is waiting...\";sleep 5;done"
#   }
#
#   provisioner "file" {
#     content = templatefile("${path.module}/templates/join.sh",
#       {
#         cluster_token = random_id.cluster_token.hex
#         main_node     = var.initiator_node.host
#       })
#     destination = "/tmp/join.sh"
#   }
#
#   provisioner "remote-exec" {
#     inline = [
#       "sh /tmp/join.sh",
#     ]
#   }
#
#   provisioner "local-exec" {
#     interpreter = ["bash", "-c"]
#     command = "echo \"${count.index+2}\" > /tmp/current_joining_node.txt"
#   }
# }
#
#
# resource "null_resource" "get_kubeconfig" {
#   depends_on = [null_resource.setup_tokens]
#
#   provisioner "local-exec" {
#     command = "echo ${var.initiator_node.private_key} | scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /dev/stdin  ${var.initiator_node.user}@${var.initiator_node.host}:/tmp/config/client.config /tmp/"
#   }
# }