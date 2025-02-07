terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.4.0"
    }
  }
}

provider "github" {
  owner = "KahfAds"
}

data "github_repository" "this" {
  name = "ethical-ad-server"
}

variable "registry" {
  type = object({
    address = string
    username = string
    password = string
  })
}

variable "docker" {
  type = object({
    host    = string
    cert    = string
    key     = string
    ca_cert = string
  })
}

variable "env" {}

resource "github_actions_secret" "ACR_USERNAME" {
  repository       = data.github_repository.this.name
  secret_name      = "${upper(var.env)}_ACR_USERNAME"
  plaintext_value  = var.registry.username
}

resource "github_actions_secret" "ACR_PASSWORD" {
  repository       = data.github_repository.this.name
  secret_name      = "${upper(var.env)}_ACR_PASSWORD"
  plaintext_value  = var.registry.password
}

resource "github_actions_secret" "DOCKER_TLS_CA" {
  repository       = data.github_repository.this.name
  secret_name      = "${upper(var.env)}_DOCKER_TLS_CA"
  plaintext_value  = var.docker.ca_cert
}

resource "github_actions_secret" "DOCKER_TLS_CERT" {
  repository       = data.github_repository.this.name
  secret_name      = "${upper(var.env)}_DOCKER_TLS_CERT"
  plaintext_value  = var.docker.cert
}

resource "github_actions_secret" "DOCKER_TLS_KEY" {
  repository       = data.github_repository.this.name
  secret_name      = "${upper(var.env)}_DOCKER_TLS_KEY"
  plaintext_value  = var.docker.key
}

resource "github_actions_secret" "DOCKER_HOST" {
  repository       = data.github_repository.this.name
  secret_name      = "${upper(var.env)}_DOCKER_HOST"
  plaintext_value  = var.docker.host
}


