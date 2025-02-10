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
  error_notification_admins = "mazharul,mazharul@kahf.co;"
  server_email = "no-reply@kahfads.com"
}