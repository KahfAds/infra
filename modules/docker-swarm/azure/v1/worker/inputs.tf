variable "name_prefix" {}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "subnet" {
  type = object({
    id = string
    prefix = string
  })
}

variable "network" {
  type = object({
    prefix = string
  })
}

variable "size" {
  default = "Standard_B2s"
}

variable "custom_data" {
  type = string
  default = ""
}

variable "join_command" {}