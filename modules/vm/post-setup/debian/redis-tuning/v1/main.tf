variable "redis_installed_on_vm" {
  type = bool
}

variable "redis_on_docker" {
  type = bool
}

output "script" {
  value = var.redis_installed_on_vm ? concat(local.system_commands, local.redis_commands) :
      var.redis_on_docker ? concat(local.system_commands, local.docker_commands) : local.system_commands
}

output "daemon_json" {
  value = jsonencode({
    default-ulimits: {
      nofile: {

      }
    }
  })
}

locals {
  system_commands = [
    # 1️⃣ Increase max open files (file descriptors)
    "echo '* soft nofile 1000000' | sudo tee -a /etc/security/limits.conf",
    "echo '* hard nofile 1000000' | sudo tee -a /etc/security/limits.conf",
    "echo 'fs.file-max=2097152' | sudo tee -a /etc/sysctl.conf",

    # 2️⃣ Tune TCP backlog & networking
    "echo 'net.core.somaxconn=65535' | sudo tee -a /etc/sysctl.conf",
    "echo 'net.core.netdev_max_backlog=65535' | sudo tee -a /etc/sysctl.conf",
    "echo 'net.ipv4.tcp_max_syn_backlog=65535' | sudo tee -a /etc/sysctl.conf",
    "echo 'net.ipv4.tcp_fin_timeout=15' | sudo tee -a /etc/sysctl.conf",
    "echo 'net.ipv4.tcp_tw_reuse=1' | sudo tee -a /etc/sysctl.conf",
    "sudo sysctl -p"
  ]

  redis_commands = [
    [
      # Configure Redis to allow more connections
      "echo 'maxclients 50000' | sudo tee -a /etc/redis/redis.conf",
      "echo 'timeout 0' | sudo tee -a /etc/redis/redis.conf",
      "echo 'tcp-backlog 65535' | sudo tee -a /etc/redis/redis.conf",

      # Restart Redis to apply changes
      "sudo systemctl restart redis"
    ]
  ]

  docker_commands = [
    "echo '{ \"default-ulimits\": { \"nofile\": { \"Name\": \"nofile\", \"Soft\": 1000000, \"Hard\": 1000000 } } }' | sudo tee /etc/docker/daemon.json",
    "sudo systemctl restart docker"
  ]
}