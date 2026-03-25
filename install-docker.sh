#!/bin/bash
# DigitalOcean Deployment Script for GetToPeru
# Run this on a fresh Ubuntu 22.04 Droplet

set -e

echo "=== GetToPeru DigitalOcean Deployment ==="
echo "Installing Docker and dependencies..."

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add current user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Git
sudo apt-get install -y git

# Install Certbot for SSL
sudo apt-get install -y certbot python3-certbot-nginx

echo "Docker and dependencies installed successfully!"
echo ""
echo "Next steps:"
echo "1. Point your domain DNS to this droplet's IP"
echo "2. Clone your project: git clone <your-repo>"
echo "3. Run: bash deploy.sh <your-domain.com>"
