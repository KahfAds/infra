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
      port = local.ingress.dashboard_port
      protocol = "Tcp"
      public = false
    },
    {
      name = "ingress-web"
      port = local.ingress.web_port
      protocol = "Tcp"
      public = false
    },
    {
      name = "ingress-websecure"
      port = local.ingress.websecure_port
      protocol = "Tcp"
      public = false
    }
  ]

  ingress = {
    web_port = 30080
    websecure_port = 30443
    dashboard_port = 30880
  }
}