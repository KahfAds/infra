variable "google_client_id" {}

variable "google_client_secret" {}

module "dex" {
  source = "../../../modules/k8s-applications/dex"
  google_client_id     = var.google_client_id
  google_client_secret = var.google_client_secret
  name_prefix          = "default"
  reachable_domain     = "dex.${var.root_domain}"
  root_domain          = "*.${var.root_domain}"
  cluster_issuer = module.cluster_issuer.name
  ingress_class = module.traefik.class_name
}

module "traefik-forward-auth" {
  source = "../../../modules/k8s-applications/oidc-suites/traefik-forward-auth"
}