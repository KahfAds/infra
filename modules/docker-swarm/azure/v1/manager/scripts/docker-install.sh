#!/bin/bash

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo apt-get update && sudo apt-get install -y uidmap jq
dockerd-rootless-setuptool.sh install
sudo loginctl enable-linger azure-user

# Configure firewall to enable Docker Swarm ports
yes | sudo ufw enable

sudo ufw allow 22/tcp
sudo ufw allow 2376/tcp
sudo ufw allow 2377/tcp
sudo ufw allow 7946/tcp
sudo ufw allow 7946/udp
sudo ufw allow 4789/udp
sudo ufw allow 8080/tcp

sudo ufw reload