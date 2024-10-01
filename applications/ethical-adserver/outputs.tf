output "this" {
  value = {
    swarm = {
      leader_ip = module.swarm_cluster.ssh.ip_address
    }
  }
}