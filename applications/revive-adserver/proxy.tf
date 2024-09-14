module "proxy" {
  source = "../traefik"
  registry = local.registry
  docker = module.swarm_cluster.docker
}