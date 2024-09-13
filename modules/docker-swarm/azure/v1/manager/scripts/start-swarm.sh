#!/bin/bash
# Get private IP
PRIVATE_IP=$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | jq -r ".network.interface[0].ipv4.ipAddress[0].privateIpAddress")

# Start Swarm
echo "Starting swarm init..."
docker swarm init \
--advertise-addr "$PRIVATE_IP"