#!/bin/bash
# Deployment script for GetToPeru on DigitalOcean

DOMAIN=${1:-gettoperu.com}
EMAIL=${2:-admin@gettoperu.com}

if [ "$DOMAIN" = "yourdomain.com" ]; then
    echo "Usage: bash deploy.sh gettoperu.com admin@gettoperu.com"
    exit 1
fi

set -e

echo "=== Deploying GetToPeru to $DOMAIN ==="

# 1. Create app directory
sudo mkdir -p /opt/gettoperu
cd /opt/gettoperu

# 2. Clone repository (if not already present)
if [ ! -d ".git" ]; then
    echo "Cloning repository..."
    sudo git clone <YOUR_REPO_URL> .
fi

# 3. Pull latest code
echo "Pulling latest code..."
sudo git pull origin main

# 4. Create environment file
echo "Creating environment configuration..."
sudo tee .env > /dev/null << EOF
DOMAIN=$DOMAIN
EMAIL=$EMAIL
EOF

# 5. Generate SSL certificate with Let's Encrypt
echo "Generating SSL certificate..."
sudo certbot certonly \
    --standalone \
    --non-interactive \
    --agree-tos \
    --email $EMAIL \
    -d $DOMAIN \
    || echo "SSL certificate already exists or failed (may already be set up)"

# 6. Copy SSL certificates to app directory
sudo mkdir -p /opt/gettoperu/ssl
sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem /opt/gettoperu/ssl/cert.pem
sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem /opt/gettoperu/ssl/key.pem
sudo chown -R $USER:$USER /opt/gettoperu/ssl

# 7. Start containers
echo "Starting Docker containers..."
docker compose -f docker-compose.prod.yml up -d

# 8. Setup Nginx reverse proxy (optional, for production)
echo "Configuring Nginx reverse proxy..."
sudo apt-get install -y nginx

sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://127.0.0.1:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable site
sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test and reload Nginx
sudo nginx -t
sudo systemctl restart nginx

# 9. Setup auto-renewal for SSL
echo "Setting up SSL auto-renewal..."
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

# 10. Display status
echo ""
echo "=== Deployment Complete ==="
echo "Website: https://$DOMAIN"
echo "Nginx status: $(sudo systemctl is-active nginx)"
echo ""
echo "Useful commands:"
echo "  View logs: docker compose -f docker-compose.prod.yml logs -f web"
echo "  Restart: docker compose -f docker-compose.prod.yml restart"
echo "  Stop: docker compose -f docker-compose.prod.yml down"
