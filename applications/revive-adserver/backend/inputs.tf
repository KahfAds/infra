variable "docker" {
  type = object({
    host    = string
    cert    = string
    key     = string
    ca_cert = string
  })
}

variable "database" {
  type = object({
    host = string
    name = string
    username = string
    password = string
  })
}

variable "resource_group" {
  type = object({
    name = string
    location = string
  })
}
