output "worker_join_command" {
  value = data.external.worker_join_command.result.output
}

output "ssh" {
  value = {
    file = module.ssh_key.private_key_location
    username = local.admin_username
    ip_address = module.node.public_ip_address
  }
}