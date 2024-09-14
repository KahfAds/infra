output "ssh" {
  value = module.manager.ssh
}

output "join_command" {
  value = module.manager.worker_join_command
}

output "docker" {
  value = module.manager.docker
}