#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Variables
NODE_EXPORTER_VERSION="1.8.2" # Update to the desired version
NODE_EXPORTER_USER="node_exporter"
INSTALL_DIR="/usr/local/bin"
SERVICE_FILE="/etc/systemd/system/node_exporter.service"

# Update and install prerequisites
sudo apt-get update -y
sudo apt-get install -y curl tar

# Create a dedicated user
if ! id -u "$NODE_EXPORTER_USER" >/dev/null 2>&1; then
  sudo useradd --no-create-home --shell /bin/false "$NODE_EXPORTER_USER"
fi

# Download and install Node Exporter
curl -LO "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
tar -xzf "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
sudo mv "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" "$INSTALL_DIR"
rm -rf "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64"*
sudo chown "$NODE_EXPORTER_USER":"$NODE_EXPORTER_USER" "$INSTALL_DIR/node_exporter"

# Create the Node Exporter systemd service file
sudo bash -c "cat > $SERVICE_FILE" <<EOL
[Unit]
Description=Prometheus Node Exporter
Documentation=https://prometheus.io/docs/concepts/collector/
Wants=network-online.target
After=network-online.target

[Service]
User=$NODE_EXPORTER_USER
Group=$NODE_EXPORTER_USER
Type=simple
ExecStart=$INSTALL_DIR/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd and start Node Exporter
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
