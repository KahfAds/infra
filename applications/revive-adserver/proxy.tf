module "proxy" {
  source = "../traefik"
  registry = local.registry
  docker = module.swarm_cluster.docker
  manager_private_ip = local.manager_0_private_ip
}