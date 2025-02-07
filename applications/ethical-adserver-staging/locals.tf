locals {
  ingress = {
    web_port = 80
    websecure_port = 443
    dashboard_port = 8080
  }
  name_prefix = "kahfads"
  qrm = {
    app_url = "https://qr.${local.root_domain}"
  }
}