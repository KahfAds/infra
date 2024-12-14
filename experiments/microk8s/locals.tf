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
      name = "web"
      port = 80
      protocol = "Tcp"
      public = true
    },
    {
      name = "websecure"
      port = 443
      protocol = "Tcp"
      public = true
    },
    {
      name = "microk8s-cluster"
      port = 25000
      protocol = "Tcp"
      public = true
    },
    {
      name = "k8s"
      port = 16443
      protocol = "Tcp"
      public = true
    },
    {
      name = "ingress"
      port = 8080
      protocol = "Tcp"
      public = true
    }
  ]
}