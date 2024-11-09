variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
}

variable "storage_account_type" {
  default = "Standard_LRS"
  type    = string
}

variable "disk_size_gb" {
  type    = number
  default = 100
}

variable "create_option" {
  type    = string
  default = "Empty"
}

variable "name_prefix" {}

variable "virtual_machine_id" {}

variable "logical_unit_number" {
  type = number
}

variable "caching" {
  default = "ReadWrite"
}

variable "ssh" {
  type = object({
    host        = string
    username    = string
    private_key = string
  })
}

variable "mount_point" {}