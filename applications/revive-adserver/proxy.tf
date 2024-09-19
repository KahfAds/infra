module "proxy" {
  source = "../../modules/docker-swarm/edge-routers/traefik/v1"
  registry = local.registry
  docker = module.swarm_cluster.docker
}