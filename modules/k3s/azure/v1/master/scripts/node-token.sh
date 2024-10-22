#!/bin/bash

# Arguments passed to the script
ENCODED_SSH_KEY="$1"
ADMIN_USERNAME="$2"
PUBLIC_IP="$3"

# Decode the SSH key
SSH_KEY=$(echo "$ENCODED_SSH_KEY" | base64 --decode)

# Create a temporary file for the SSH key
tempfile=$(mktemp)
echo "$SSH_KEY" > "$tempfile"
chmod 600 "$tempfile"
# Run the SSH command to get the 'docker swarm join-token' result
RESULT=$(ssh -i "$tempfile" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ADMIN_USERNAME@$PUBLIC_IP" "sudo cat /var/lib/rancher/k3s/server/node-token" 2>&1)

# Clean up the temporary file
rm -f "$tempfile"

# Output the result as a valid JSON object for Terraform
echo "{\"output\": $RESULT}"