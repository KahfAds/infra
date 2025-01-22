locals {
  env = "test"

  ingress = {
    web_port = 80
    websecure_port = 443
    dashboard_port = 8080
  }

  blocked_ips = [
  ]
}