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
  repository       = data.github_repository.this.name
  secret_name      = "${upper(var.env)}_AZURE_STORAGE_ACCOUNT"
  plaintext_value  = var.AZURE_STORAGE_ACCOUNT
}

resource "github_actions_secret" "AZURE_CREDS" {
  repository       = data.github_repository.this.name
  secret_name      = "${upper(var.env)}_AZURE_CREDS"
  plaintext_value  = jsonencode({
    clientSecret = var.AZURE_CLIENT_SECRET
    subscriptionId =  var.AZURE_SUBSCRIPTION_ID
    tenantId =  var.AZURE_TENANT_ID
    clientId =  var.AZURE_CLIENT_ID
  })
}