locals {
  commands = {
    delete_all_secrets = ["[ \"$(sudo docker secret ls -q)\" ] && sudo docker secret rm $(sudo docker secret ls -q) || echo \"No secrets to delete.\""]
    add_all_secrets = flatten([
      for secret_name, secret_value in var.docker_secrets : [
        "echo '${secret_value}' | sudo docker secret create ${secret_name} -"
      ]
    ])
  }
}