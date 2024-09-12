#!/bin/bash

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo apt-get update && sudo apt-get install -y uidmap jq
dockerd-rootless-setuptool.sh install

# Configure firewall to enable Docker Swarm ports
yes | sudo ufw enable

sudo ufw allow 2377,7946/tcp
sudo ufw allow 4789,7946/udp
sudo ufw reload

sudo ${JOIN_COMMAND}