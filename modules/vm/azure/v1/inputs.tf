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


variable "public_key" {
  type = string
}

variable "custom_data" {
  type = string
  default = ""
}

variable "subnet_id" {}

variable "private_key_location" {}

variable "remote_exec_scripts" {
  type = list(string)
  default = []
}

variable "local_exec_command" {
  type = string
  default = "/bin/sh"
}

variable "network_interface" {
  type = object({
    id = string
    public_ip_address = string
  })
}