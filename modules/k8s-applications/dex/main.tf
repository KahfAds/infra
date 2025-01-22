variable "ingress_class" {}

variable "cluster_issuer" {}

variable "name_prefix" {}

variable "reachable_domain" {}

variable "root_domain" {}

variable "google_client_id" {}

variable "google_client_secret" {}

resource "random_password" "dex_static_client_secret" {
  length  = 32
  special = false # Set to true if special characters are allowed
}

resource "helm_release" "this" {
  name             = "${var.name_prefix}-dex"
  namespace        = "${var.name_prefix}-dex"
  chart            = "dex"
  repository       = "https://charts.dexidp.io"
  create_namespace = true
  version          = "0.20.0"

  values = [
    templatefile("${path.module}/values.yaml", {
      dex_service_url          = var.reachable_domain
      google_client_id         = var.google_client_id
      google_client_secret     = var.google_client_secret
      allowed_domain           = var.root_domain
      dex_static_client_secret = random_password.dex_static_client_secret.result
      cluster_issuer           = var.cluster_issuer
      ingress_class            = var.ingress_class
      clients                  = []
    })
  ]
}