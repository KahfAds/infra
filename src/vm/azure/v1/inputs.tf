variable "admin_username" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "location" {
  default = "southeastasia"
}

variable "size" {
  default = "Standard_B2s"
}

variable "availability_set_id" {}


variable "rsa_key_name" {
  type = string
}

variable "custom_data" {
  type = string
  default = ""
}

variable "subnet_id" {}