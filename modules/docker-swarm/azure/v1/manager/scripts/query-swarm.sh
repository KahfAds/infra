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
# Read input from stdin
read -r json_input
# Parse input JSON
TOKEN_TYPE=$(echo "$json_input" | jq -r '.args')
# Run the SSH command to get the 'docker swarm join-token' result
RESULT=$(ssh -i "$tempfile" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ADMIN_USERNAME@$PUBLIC_IP" "sudo docker swarm join-token $TOKEN_TYPE" 2>&1)

# Clean up the temporary file
rm -f "$tempfile"

# Extract the line with 'docker swarm join' and remove extra indentation
SWARM_JOIN_LINE=$(echo "$RESULT" | awk '/docker swarm join/ {print $0}' | sed 's/^.*docker swarm join/docker swarm join/' | tr -d '\r' | tr -d '\n' | sed 's/[[:space:]]*$//')

# If the result is empty, return an error message as JSON
if [ -z "$SWARM_JOIN_LINE" ]; then
    echo "{\"error\": \"No valid docker swarm join-token output received\"}"
    exit 1
fi

# Escape the result for valid JSON
ESCAPED_RESULT=$(echo -n "$SWARM_JOIN_LINE" | jq -Rsa '.')

# Output the result as a valid JSON object for Terraform
echo "{\"output\": $ESCAPED_RESULT}"