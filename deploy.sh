#!/bin/bash
DOMAIN=${1:-gettoperu.com}
EMAIL=${2:-admin@gettoperu.com}

if [ "$DOMAIN" = "yourdomain.com" ]; then
    echo "Usage: bash deploy.sh gettoperu.com admin@gettoperu.com"
    exit 1
fi

set -e

echo "=== Deploying GetToPeru to $DOMAIN ==="

sudo mkdir -p /opt/gettoperu
cd /opt/gettoperu

if [ ! -d ".git" ]; then
    echo "Cloning repository..."
    sudo git clone https://github.com/LuisRomani/GetToPeru.git .
fi

echo "Pulling latest code..."
sudo git pull origin main

sudo tee .env > /dev/null << EOF
DOMAIN=$DOMAIN
EMAIL=$EMAIL
EOF

echo "Starting Docker containers..."
sudo docker compose -f docker-compose.prod.yml up -d

echo "=== Deployment Complete ==="
echo "Website: https://$DOMAIN"
echo "View logs: docker compose -f docker-compose.prod.yml logs -f web"
