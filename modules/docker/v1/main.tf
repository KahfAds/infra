terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {
  alias = "remote"
  host = "tcp://${var.docker.host}:2376"
  cert_material = var.docker.cert
  ca_material = var.docker.ca_cert
  key_material = var.docker.key
}

variable "configs" {
  type = list(object({
    name = string
    data = string
  }))
  default = []
}

variable "networks" {
  type = list(string)
  default = []
}

resource "docker_config" "this" {
  for_each = { for config in var.configs: config.name => config.data }

  name = each.key
  data = base64encode(each.value)
}

resource "docker_network" "this" {
  for_each = { for network in var.networks : network => network }

  name = each.key
}