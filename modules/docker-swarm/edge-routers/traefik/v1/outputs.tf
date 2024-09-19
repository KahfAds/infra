output "password" {
  value = random_password.basic_auth.result
  sensitive = false
}

output "service" {
  depends_on = [docker_network.this]
  value = base64encode(templatefile("${path.module}/docker-compose.yaml",{
    password = sha1("admin")
    network_name = docker_network.this.name
  }))
}