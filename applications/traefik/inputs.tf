variable "registry" {
  type = object({
    address = string
    username = string
    password = string
  })
}
