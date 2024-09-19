#!/bin/bash

# Install Docker
sudo apt-get update && sudo apt-get install -y docker.io uidmap jq nfs-common
sudo loginctl enable-linger azure-user

# Configure firewall to enable Docker Swarm ports
yes | sudo ufw enable

sudo ufw allow 2377,7946/tcp
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