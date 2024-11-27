module "backend" {
  source = "./stacks/backend"
  docker = module.swarm_cluster.docker
  registry = local.registry
}