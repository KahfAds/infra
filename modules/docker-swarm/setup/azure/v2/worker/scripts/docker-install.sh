#!/bin/bash
# 1️⃣ Increase max open files (file descriptors)
echo '* soft nofile 1000000' | sudo tee -a /etc/security/limits.conf
echo '* hard nofile 1000000' | sudo tee -a /etc/security/limits.conf
echo 'fs.file-max=2097152' | sudo tee -a /etc/sysctl.conf

# 2️⃣ Tune TCP backlog & networking
echo 'net.core.somaxconn=65535' | sudo tee -a /etc/sysctl.conf
echo 'net.core.netdev_max_backlog=65535' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_max_syn_backlog=65535' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_fin_timeout=15' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_tw_reuse=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Install Docker
echo '{ "metrics-addr": "0.0.0.0:9323", "experimental": true, "default-ulimits": { "nofile": { "Name": "nofile","Soft": 65535,"Hard": 65535 } }, "log-driver": "json-file", "log-opts": { "max-size": "100m", "max-file": "3" } }' | sudo tee /etc/docker/daemon.json
sudo apt-get update && sudo apt-get install -y docker.io uidmap jq nfs-common
sudo loginctl enable-linger azure-user

# Configure firewall to enable Docker Swarm ports
yes | sudo ufw enable

sudo ufw allow 2377,7946,9323,9100/tcp
sudo ufw allow 4789,7946/udp
sudo ufw reload

# Install prerequisites
sudo apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg
# Download and install Microsoft signing key
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
# Add Azure CLI software repository
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
# Update repository and install Azure CLI
sudo apt-get update
sudo apt-get install -y azure-cli
sudo az login --identity
%{ for registry_name in accessible_registries ~}
sudo az acr login --name ${registry_name}
%{ endfor ~}

${JOIN_COMMAND}

sudo docker plugin install grafana/loki-docker-driver:2.9.2 --alias loki --grant-all-permissions