output "password" {
  value = random_password.basic_auth.result
  sensitive = false
}