resource "random_password" "basic_auth" {
  length = 12
  special = true
  override_special = "_%@"
}
