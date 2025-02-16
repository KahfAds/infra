variable "sendgrid_api_key" {
  type = string
}

variable "secret_key" {
  type = string
}

variable "sender_email" {
  type = string
  default = "mazharul@kahf.co"
}

variable "metabase_secret_key" {
  type = string
}

variable "metabase_embed_key" {
  type = string
}

variable "cdn_sku" {
  type        = string
  description = "CDN SKU names."
  default     = "Standard_Microsoft"
  validation {
    condition     = contains(["Standard_Akamai", "Standard_Microsoft", "Standard_Verizon", "Premium_Verizon"], var.cdn_sku)
    error_message = "The cdn_sku must be one of the following: Standard_Akamai, Standard_Microsoft, Standard_Verizon, Premium_Verizon."
  }
}

variable "qrm" {
  type = object({
    app_key = string
    app_url = string
    ip_stack_access_key = string
  })
}

variable "proxy_dashboard" {
  type = object({
    oidc_client_id = string
    oidc_client_secret = string
  })
}

variable "smtp" {
  type = object({
    host = string
    port = string
    username = string
    password = string
  })
}