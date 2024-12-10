#!/bin/bash

# disable kernel update message
sudo sed -i "s/#\$nrconf{kernelhints} = -1;/\$nrconf{kernelhints} = -1;/g" /etc/needrestart/needrestart.conf

# Update the package database
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y

# Install snapd
sudo apt install -y snapd

# Install the required packages
sudo apt install -y nfs-kernel-server bridge-utils open-iscsi

# Start the iscsid service
sudo systemctl start iscsid

# Install MicroK8s using snap
sudo snap install microk8s --channel=1.30/stable --classic