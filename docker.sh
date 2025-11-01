#!/bin/bash

echo "Updating Linux..."
sudo apt update -y
echo "Linux Updated"

## Docker installation
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
#post install
sudo groupadd docker  # Ensure the docker group exists
sudo usermod -aG docker $USER
newgrp docker  # Activate group changes immediately
echo "Docker Instaled"

## AWS CLI
echo "Installing AWS CLI..."
sudo sudo snap install aws-cli --classic
echo "AWS CLI Installed"

sudo sh ecr_login.sh

# Update hostname
sudo vi /etc/hosts
sudo vi /etc/hostname
sudo reboot

# Create jenkins ssh
ssh-keygen -t ecdsa -m PEM -f ~/.ssh/jenkins_agent_api_rsa
cat ~/.ssh/jenkins_agent_api_rsa.pub >> ~/.ssh/authorized_keys