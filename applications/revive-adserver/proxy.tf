module "proxy" {
  source = "../../modules/docker-swarm/edge-routers/traefik/v1"
  network_name = local.docker_network_name
}