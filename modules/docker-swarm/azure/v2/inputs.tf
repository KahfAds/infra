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

variable "accessible_registries" {
  type = list(string) # [name]
  default = []
}

variable "roles" {
  type = map(string) # { role_definition_name = scope }
  default = {}
}

variable "worker_scale" {
  type = object({
    min = number
    max = number
    desired = number
  })

  default = {
    min = 1
    max = 3
    desired = 3
  }
}