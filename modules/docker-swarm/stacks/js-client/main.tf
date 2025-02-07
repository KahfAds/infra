terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.4.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
  }
}

provider "github" {
  owner = "KahfAds"
}

data "github_repository" "this" {
  name = "ethical-ad-server-client"
}

variable "AZURE_CLIENT_ID" {}

variable "AZURE_CLIENT_SECRET" {}

variable "AZURE_TENANT_ID" {}

variable "AZURE_STORAGE_ACCOUNT" {}

variable "AZURE_SUBSCRIPTION_ID" {}

variable "env" {}

resource "github_actions_secret" "AZURE_STORAGE_ACCOUNT" {
  repository      = data.github_repository.this.name
  secret_name     = "${upper(var.env)}_AZURE_STORAGE_ACCOUNT"
  plaintext_value = var.AZURE_STORAGE_ACCOUNT
}

resource "github_actions_secret" "AZURE_CREDS" {
  repository  = data.github_repository.this.name
  secret_name = "${upper(var.env)}_AZURE_CREDS"
  plaintext_value = jsonencode({
    clientSecret   = var.AZURE_CLIENT_SECRET
    subscriptionId = var.AZURE_SUBSCRIPTION_ID
    tenantId       = var.AZURE_TENANT_ID
    clientId       = var.AZURE_CLIENT_ID
  })
}

resource "azurerm_storage_container" "this" {
  name                  = "media"
  storage_account_name  = var.AZURE_STORAGE_ACCOUNT
  container_access_type = "blob"
}

variable "backend_domain" {}

variable "asset_domain" {}

resource "azurerm_storage_blob" "px_gif" {
  name                   = "abp/px.gif"
  storage_account_name   = var.AZURE_STORAGE_ACCOUNT
  storage_container_name = azurerm_storage_container.this.name
  type                   = "Block"
  source                 = "${path.module}/px.gif"
  content_md5            = filemd5("${path.module}/px.gif")
  content_type           = "image/gif"
}

resource "azurerm_storage_blob" "client_js" {
  name                   = "client/kahfads.min.js"
  storage_account_name   = var.AZURE_STORAGE_ACCOUNT
  storage_container_name = azurerm_storage_container.this.name
  type                   = "Block"
  source_content = templatefile("${path.module}/client.min.js", {
    backend_domain = var.backend_domain
    asset_domain   = var.asset_domain
  })
  content_type = "application/javascript"
}