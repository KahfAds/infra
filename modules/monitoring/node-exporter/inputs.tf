variable "ssh" {
  type = object({
    private_key_pem = string
    username = string
    ip_address = string
  })
}

variable "collectors" {
  description = "Map of Node Exporter collectors and their arguments"
  type        = map(string)
  default     = {}
}

