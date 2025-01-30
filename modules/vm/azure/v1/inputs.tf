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


variable "public_key" {
  type = string
}

variable "custom_data" {
  type = string
  default = ""
}

variable "private_key_pem" {}

# variable "remote_exec_scripts" {
#   type = list(string)
#   default = []
# }
#
# variable "local_exec_command" {
#   type = string
#   default = "/bin/sh"
# }

variable "publicly_accessible" {
  type = bool
  default = false
}

variable "allowed_ports" {
  type = list(object({
    access = string
    name = string
    port = number
    protocol = string
    source_address_prefix = string
  }))
}

variable "private_ip_address" {
  type = string
  default = ""
}

variable "network" {
  type = object({
    prefix = string
  })
}

variable "subnet" {
  type = object({
    id = string
    prefix = string
  })
}

variable "additional_identities" {
  type = map(list(string)) # { type = [identity_ids]}
  default = {}
}

variable "zone" {
  default = "2"
}
