# resource "null_resource" "swarm_prometheus" {
#   connection {
#     user = module.swarm_cluster.ssh.username
#     type = "ssh"
#     private_key = file(module.swarm_cluster.ssh.file)
#     host = module.swarm_cluster.ssh.ip_address
#   }
#   provisioner "file" {
#     source = "../../modules/swarm-prometheus"
#   }
# }