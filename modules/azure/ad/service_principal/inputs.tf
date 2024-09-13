variable "name_prefix" {}

variable "password_expiration_date" {
  default = "2099-01-01T00:00:00Z"
}

variable "scope_id" {}

variable "role_definition_name" {
  type    = string
  default = "Reader"
}