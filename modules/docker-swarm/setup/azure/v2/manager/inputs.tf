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

variable "private_ip_address" {}

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

variable "size" {
  default = "Standard_D2ads_v5"
}

variable "accessible_registries" {
  type = list(string) # [name]
  default = []
}

variable "roles" {
  type = map(string) # { role_definition_name = scope }
  default = {}
}

variable "replica" {
  type = number
  default = 2
}

variable "create_docker_context" {
  type = bool
}