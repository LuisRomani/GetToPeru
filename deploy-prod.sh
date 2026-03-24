#!/bin/bash
# Production Deployment Script

set -e

echo "=== GetToPeru Production Deployment ==="

# 1. Update msmtp config for production SMTP
cat > /etc/msmtprc << EOF
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
domain yourdomain.com
host ${SMTP_HOST}
port ${SMTP_PORT}
user ${SMTP_USER}
password ${SMTP_PASSWORD}
from ${SMTP_FROM}

account default
host ${SMTP_HOST}
port ${SMTP_PORT}
user ${SMTP_USER}
password ${SMTP_PASSWORD}
from ${SMTP_FROM}
EOF

chmod 600 /etc/msmtprc

# 2. Pull latest image
echo "Pulling latest image..."
docker pull gettoperu:latest

# 3. Stop running containers
echo "Stopping containers..."
docker compose -f docker-compose.prod.yml down

# 4. Start production stack
echo "Starting production stack..."
docker compose -f docker-compose.prod.yml up -d

# 5. Check health
echo "Checking container health..."
sleep 10
docker compose -f docker-compose.prod.yml ps

echo "=== Deployment Complete ==="
echo "Website: https://yourdomain.com"
echo "phpMyAdmin: https://yourdomain.com:8080 (if exposed)"
