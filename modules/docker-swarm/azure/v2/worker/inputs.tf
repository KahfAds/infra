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

variable "scale" {
  type = object({
    min = number
    max = number
    desired = number
  })

  default = {
    min = 1
    max = 2
    desired = 2
  }
}

variable "accessible_registries" {
  type = list(string) # [name]
  default = []
}

variable "roles" {
  type = map(string) # { role_definition_name = scope }
  default = {}
}