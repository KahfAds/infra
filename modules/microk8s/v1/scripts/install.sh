#!/bin/bash

# Define variables
MICROK8S_CHANNEL="${microk8s_channel:-stable}" # Default channel if not specified

# Update the package database
sudo apt update
sudo apt upgrade

# Install snapd
sudo apt install snapd

# Install the required packages
sudo apt install -y nfs-kernel-server bridge-utils open-iscsi

# Start the iscsid service
sudo systemctl start iscsid

# Install MicroK8s using snap
sudo snap install microk8s --channel="${MICROK8S_CHANNEL}" --classic