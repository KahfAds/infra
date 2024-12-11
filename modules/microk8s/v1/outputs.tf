output "token" {
  value = {
    command = data.external.add_node_token.result.command
    token = data.external.add_node_token.result.token
  }
}