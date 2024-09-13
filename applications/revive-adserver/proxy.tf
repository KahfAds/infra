module "proxy" {
  source = "../traefik"
  registry = local.registry
}