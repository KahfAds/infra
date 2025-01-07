output "token" {
  value = {
    command = data.external.add_node_token.result.command
    token = data.external.add_node_token.result.token
  }
}

output "kubeconfig" {
  value = replace(base64decode(data.external.kubeconfig.result["kubeconfig_content"]), "127.0.0.1", var.initiator_node.host)
  sensitive = true
}

output "ingress" {
  value = local.ingress
}