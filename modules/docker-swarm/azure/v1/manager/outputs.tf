output "worker_join_command" {
  value = data.external.worker_join_command.result.output
}

output "ssh" {
  value = {
    private_key_pem = module.ssh_key.private_key_pem
    username = local.admin_username
    ip_address = module.node.public_ip_address
  }
}