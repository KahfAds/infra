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