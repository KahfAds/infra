terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.31.0"
    }
  }
}

resource "helm_release" "this" {
  name       = "rook-ceph"
  chart      = "rook-ceph"
  namespace  = "rook-ceph"
  repository = "https://charts.rook.io/release"
  create_namespace = true
}