locals {
  env = "staging"

  ingress = {
    web_port = 80
    websecure_port = 443
    dashboard_port = 8080
  }

  blocked_ips = [
  ]
  root_domain = "staging.kahfads.com"
  name_prefix = "kahfads"

  qrm = {
    app_url = "https://qr.${local.root_domain}"
  }
}