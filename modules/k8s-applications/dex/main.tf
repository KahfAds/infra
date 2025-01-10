variable "name_prefix" {

}

resource "helm_release" "dex" {
  name       = "${var.name_prefix}-dex"
  namespace  = "${var.name_prefix}-dex"
  chart      = "dex"
  repository = "https://charts.dexidp.io"
  create_namespace = true

  set {
    name  = "grpc"
    value = "true"
  }

  set {
    name  = "http"
    value = "true"
  }

  set {
    name  = "ingress.enabled"
    value = "true"
  }

  set {
    name  = "config.issuer"
    value = "https://dex.example.com"
  }

  set {
    name  = "config.staticClients[0].id"
    value = "example-app"
  }

  set {
    name  = "config.staticClients[0].secret"
    value = "example-app-secret"
  }

  set {
    name  = "config.staticClients[0].redirectURIs[0]"
    value = "http://localhost:5555/callback"
  }

  set {
    name  = "config.connectors[0].type"
    value = "oidc"
  }

  set {
    name  = "config.connectors[0].id"
    value = "azure"
  }

  set {
    name  = "config.connectors[0].name"
    value = "Azure"
  }

  set {
    name  = "config.connectors[0].config.issuer"
    value = "https://login.microsoftonline.com/<tenant-id>/v2.0"
  }

  set {
    name  = "config.connectors[0].config.clientID"
    value = "<azure-client-id>"
  }

  set {
    name  = "config.connectors[0].config.clientSecret"
    value = "<azure-client-secret>"
  }
}