variable "initiator_node" {
  type = object({
    host = string
    user = string
    private_key = string
    private_ip = string
    hostname = string
  })
}

variable "master_nodes" {
  type = list(object({
    host = string
    user = string
    private_key = string
    private_ip = string
    hostname = string
  }))
  default = []
}

variable "worker_nodes" {
  type = list(object({
    host = string
    user = string
    private_key = string
    private_ip = string
    hostname = string
  }))
  default = []
}

variable "install_channel" {}

variable "cluster_token_ttl_seconds" {
  type        = number
  default     = 3600
  description = "The cluster token ttl to use when joining a node, default 3600 seconds."
}

variable "addons" {
  type = list(string)
}