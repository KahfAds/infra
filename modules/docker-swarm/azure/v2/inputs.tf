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

variable "manager_0_private_ip" {}

variable "network" {
  type = object({
    prefix = string
  })
}

variable "docker_secrets" {
  type = map(string)
  default = {}
  sensitive = true
}

variable "registry" {
  type = object({
    address  = string
    username = string
    password = string
  })
}