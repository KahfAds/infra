variable "auth_host" {
  default = "dex.ababil.xyz"
}

variable "allowed_email_domains" {
  default = "kahf.co"
}

variable "root_domain" {
  default = "ababil.xyz"
}


resource "helm_release" "this" {
  chart            = "traefik-forward-auth"
  name             = "traefik-forward-auth"
  repository       = "https://kahfads.github.io/charts"
  version          = "2.2.2"
  create_namespace = true
  namespace        = "traefik-forward-auth"

  values = [
    templatefile("${path.module}/values.yaml", {
      auth_host     = var.auth_host
      domain        = var.allowed_email_domains
      cookie_domain = var.root_domain
    })
  ]
}