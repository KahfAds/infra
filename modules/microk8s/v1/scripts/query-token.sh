#!/bin/bash
#!/bin/bash

# Arguments passed to the script
ENCODED_SSH_KEY="$1"
USER="$2"
HOST="$3"
PRIVATE_KEY=$(echo "$ENCODED_SSH_KEY" | base64 --decode)

# Validate arguments
if [[ -z "$HOST" || -z "$USER" || -z "$PRIVATE_KEY" ]]; then
  echo "Error: Missing required arguments: host, user, or private_key"
  exit 1
fi

# Create a temporary file for the SSH key
tempfile=$(mktemp)
echo "$PRIVATE_KEY" > "$tempfile"
chmod 600 "$tempfile"

# Run the SSH command to fetch the MicroK8s token
OUTPUT=$(ssh -i "$tempfile" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$USER@$HOST" \
                  "sudo microk8s add-node --token-ttl 3600" 2>&1)

# Clean up the temporary file
rm -f "$tempfile"

if [ -z "$OUTPUT" ]; then
  echo "Error: Failed to fetch the MicroK8s add-node command output"
  exit 1
fi

# Extract the full `microk8s join` command
JOIN_COMMAND=$(echo "$OUTPUT" | grep 'microk8s join' | head -1 | awk '{$1=""; print "microk8s "$0}' | xargs)

# Extract the token (second part of the join command: <IP>:25000/<TOKEN>/<TOKEN>)
TOKEN=$(echo "$JOIN_COMMAND" | awk '{print "microk8s "$0}' | awk -F'/' '{print $(NF-1)"/"$NF}')

# Validate extracted values
if [ -z "$JOIN_COMMAND" ] || [ -z "$TOKEN" ]; then
  echo "Error: Failed to extract the join command or token"
  exit 1
fi

# Return both the command and token as JSON
cat <<EOF
{
  "command": "$JOIN_COMMAND",
  "token": "$TOKEN"
}
EOF