#!/bin/bash

# Install Docker
sudo apt-get update && sudo apt-get install -y docker.io uidmap jq
sudo loginctl enable-linger azure-user

# Configure firewall to enable Docker Swarm ports
yes | sudo ufw enable

sudo ufw allow 2377,7946/tcp
sudo ufw allow 4789,7946/udp
sudo ufw reload

${JOIN_COMMAND}