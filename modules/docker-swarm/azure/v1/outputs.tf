output "worker_join_token" {
  depends_on = []
  value = file("${path.module}/worker-token.txt")
}

output "worker_join_command" {
  value = "docker swarm join --token ${file("${path.module}/worker-token.txt")} ${azurerm_network_interface.manager_node.private_ip_address}:2377"
}

output "manager_join_command" {
  value = ""
}

