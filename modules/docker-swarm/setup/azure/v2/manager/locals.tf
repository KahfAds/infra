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

locals {
  admin_username = "azure-user"
  program = [
    "bash",
    "${path.module}/scripts/query-swarm.sh",
    base64encode(nonsensitive(module.ssh_key.private_key_pem)),
    local.admin_username,
    azurerm_public_ip.primary.ip_address
  ]

  swarm_init = [
    "PRIVATE_IP=$(curl -s -H Metadata:true --noproxy \"*\" \"http://169.254.169.254/metadata/instance?api-version=2021-02-01\" | jq -r \".network.interface[0].ipv4.ipAddress[0].privateIpAddress\")",
    "sudo docker swarm init --default-addr-pool 10.0.0.0/8 --default-addr-pool-mask-length 24 --listen-addr \"$PRIVATE_IP\" --advertise-addr \"$PRIVATE_IP\""
  ]

  docker_install = [
    # Step 1: Create the cert directory
    "sudo mkdir -p /etc/docker/certs",
    "echo '{ \"metrics-addr\": \"0.0.0.0:9323\",\"experimental\": true,\"default-ulimits\": { \"nofile\": { \"Name\": \"nofile\",\"Soft\": 65535,\"Hard\": 65535}},\"log-driver\": \"json-file\",\"log-opts\": { \"max-size\": \"100m\",\"max-file\": \"3\"}}' | sudo tee /etc/docker/daemon.json",
    # Step 1: Write CA certificate to the correct directory
    "echo '${tls_self_signed_cert.ca_cert.cert_pem}' | sudo tee /etc/docker/certs/ca.pem",
    # Step 2: Write server certificate
    "echo '${tls_locally_signed_cert.server_cert.cert_pem}' | sudo tee /etc/docker/certs/server-cert.pem",
    # Step 3: Write server private key
    "echo '${nonsensitive(tls_private_key.server_key.private_key_pem)}' | sudo tee /etc/docker/certs/server-key.pem",
    # Step 4: Install Docker and start swarm
    "sudo apt-get clean",
    "sudo apt-get update",
    "sudo apt-get install -y docker.io uidmap jq nfs-common",
    "yes | sudo ufw enable",
    "sudo ufw allow 22/tcp",
    "sudo ufw allow 2376/tcp",
    "sudo ufw allow 2377/tcp",
    "sudo ufw allow 7946/tcp",
    "sudo ufw allow 7946/udp",
    "sudo ufw allow 4789/udp",
    "sudo ufw allow 8080/tcp",
    "sudo ufw allow 9323/tcp",
    "sudo ufw allow 9100/tcp",
    "sudo ufw reload",
    # Step 5: Configure Docker with TLS certs
    "sudo sed -i 's|ExecStart=/usr/bin/dockerd -H fd://|ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2376 --tlsverify --tlscacert=/etc/docker/certs/ca.pem --tlscert=/etc/docker/certs/server-cert.pem --tlskey=/etc/docker/certs/server-key.pem|' /lib/systemd/system/docker.service",
    # Step 6: Reload and restart Docker to apply changes
    "sudo systemctl daemon-reload",
    "sudo systemctl restart docker"
  ]

  docker_plugins = [
    "sudo docker plugin install grafana/loki-docker-driver:2.9.2 --alias loki --grant-all-permissions"
  ]
}