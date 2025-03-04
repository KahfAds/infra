output "token" {
  value = {
    command = data.external.add_node_token.result.command
    token = data.external.add_node_token.result.token
  }
}

output "kubeconfig" {
  value = base64decode(data.external.kubeconfig.result["kubeconfig_content"])
  sensitive = true
}
