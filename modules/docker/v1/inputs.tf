variable "docker" {
  type = object({
    host = string
    cert = string
    ca_cert = string
    key = string
  })
}