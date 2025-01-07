locals {
  env = "test"

  allowed_ports = [
    {
      name = "ssh"
      port = 22
      protocol = "Tcp"
      public = true
    },
    {
      name = "microk8s-cluster"
      port = 25000
      protocol = "Tcp"
      public = false
    },
    {
      name = "k8s"
      port = 16443
      protocol = "Tcp"
      public = true
    },
    {
      name = "ingress-dashboard"
      port = 30880
      protocol = "Tcp"
      public = true
    },
    {
      name = "ingress-web"
      port = 30080
      protocol = "Tcp"
      public = true
    },
    {
      name = "ingress-websecure"
      port = 30443
      protocol = "Tcp"
      public = true
    },
    {
      name = "traefik-web"
      port = 30080
      protocol = "Tcp"
      public = true
    },
    {
      name = "traefik-websecure"
      port = 30443
      protocol = "Tcp"
      public = true
    },
    {
      name = "traefik-dashboard"
      port = 30880
      protocol = "Tcp"
      public = true
    }
  ]
}