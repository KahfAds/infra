output "this" {
  value = {
    swarm = {
      ip_addresses = module.swarm_cluster.ssh.virtual_machines
    }
  }
}