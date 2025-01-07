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
OUTPUT=$(ssh -i "$tempfile" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=QUIET "$USER@$HOST" \
                  "sudo microk8s status --wait-ready && sudo microk8s config -l 2>/dev/null | base64 -w 0" 2>&1)

# Clean up the temporary file
rm -f "$tempfile"

if [ -z "$OUTPUT" ]; then
  echo "Error: Failed to fetch microk8s config"
  exit 1
fi

# Return both the command and token as JSON
cat <<EOF
{
  "kubeconfig_content": "$OUTPUT"
}
EOF