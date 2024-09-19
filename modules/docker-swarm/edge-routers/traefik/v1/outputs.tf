output "password" {
  value = random_password.basic_auth.result
  sensitive = false
}

output "service" {
  value = base64encode(templatefile("${path.module}/docker-compose.yaml",{
    password = sha1("admin")
    network_name = var.network_name
  }))
}