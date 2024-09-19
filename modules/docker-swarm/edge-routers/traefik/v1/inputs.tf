variable "registry" {
  type = object({
    address  = string
    username = string
    password = string
  })
}

variable "docker" {
  type = object({
    host    = string
    cert    = string
    key     = string
    ca_cert = string
  })
}

variable "manager_private_ip" {}
