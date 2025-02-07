output "docker" {
  value = module.manager.docker
}

output "ssh" {
  value = module.manager.ssh
}

output "network_interfaces" {
  value = {
    manager = module.manager.network_interfaces
  }
}