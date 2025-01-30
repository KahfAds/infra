variable "ssh" {
  type = object({
    user       = string
    private_key_pem = string
    host      = string
  })
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificate"
}

variable "authentik_domain" {
  description = "Domain name for GoAuthentik"
}

variable "authentik_version" {
  description = "GoAuthentik server version"
  default     = "2024.12.2"
}

variable "admin_email" {
  type = string
}
