terraform {
  required_providers {
    ssh = {
      source = "loafoe/ssh"
      version = "2.7.0"
    }
  }
}

resource "ssh_resource" "docker_secrets" {
  depends_on = [module.node, module.ssh_key]

  host = module.node.public_ip_address
  user = local.admin_username
  private_key = module.ssh_key.private_key_openssh
  agent = false

  commands = concat([
    "[ \"$(sudo docker secret ls -q)\" ] && sudo docker secret rm $(sudo docker secret ls -q) || echo \"No secrets to delete.\""
  ], flatten([
    for secret_name, secret_value in var.docker_secrets : [
      "echo '${secret_value}' | sudo docker secret create ${secret_name} -"
    ]
  ]))

  triggers = {
    secrets = md5(join(",", [for key, value in var.docker_secrets : "${key}=${value}"]))
  }
}