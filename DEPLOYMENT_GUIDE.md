# DigitalOcean Deployment Guide for GetToPeru

## Prerequisites

1. **DigitalOcean Account** - Create one at https://www.digitalocean.com
2. **Domain Name** - Register a domain (GoDaddy, Namecheap, etc.)
3. **SSH Key** - Generate SSH key for secure access

## Step 1: Create DigitalOcean Droplet

1. Go to DigitalOcean Console
2. Click "Create" → "Droplets"
3. Choose settings:
   - **Image**: Ubuntu 22.04 x64
   - **Plan**: Basic ($5/month minimum)
   - **Region**: Closest to your users
   - **Authentication**: SSH Key (recommended) or Password
4. Click "Create Droplet"

## Step 2: Point Domain to Droplet

1. Get your droplet's IP address from DigitalOcean console
2. Go to your domain registrar (GoDaddy, Namecheap, etc.)
3. Update DNS records:
   - Add `A` record: `@` → your droplet IP
   - Add `A` record: `www` → your droplet IP
   - Wait 5-15 minutes for DNS to propagate

Check DNS: `nslookup yourdomain.com`

## Step 3: SSH into Droplet

```bash
ssh root@your_droplet_ip
# Or with SSH key:
ssh -i ~/.ssh/id_rsa root@your_droplet_ip
```

## Step 4: Install Docker

```bash
bash install-docker.sh
```

This installs:
- Docker
- Docker Compose
- Git
- Certbot for SSL

## Step 5: Clone Your Project

```bash
cd /tmp
git clone https://github.com/yourusername/GetToPeru.git
cd GetToPeru
```

## Step 6: Build and Push Docker Image

On your local machine:

```bash
# Build image
docker build -t yourusername/gettoperu:latest .

# Login to Docker Hub
docker login

# Push image
docker push yourusername/gettoperu:latest
```

Update `docker-compose.prod.yml` to use your image:
```yaml
image: yourusername/gettoperu:latest
```

## Step 7: Deploy to Droplet

On the droplet:

```bash
bash deploy.sh yourdomain.com admin@yourdomain.com
```

This will:
- Clone your repository
- Generate SSL certificate (Let's Encrypt)
- Start Docker containers with Postfix SMTP
- Configure Nginx reverse proxy
- Enable auto-renewal for SSL

## Step 8: Verify Deployment

```bash
# Check containers running
docker compose -f docker-compose.prod.yml ps

# View logs
docker compose -f docker-compose.prod.yml logs -f web

# Test website
curl https://yourdomain.com
```

## Email Configuration

The setup includes **Postfix** - a local SMTP server. Emails are sent internally within the Docker network:

- **SMTP Host**: postfix (internal)
- **Port**: 25
- **From**: noreply@gettoperu.local
- **Auth**: None (local network)

Emails are processed locally but **NOT delivered externally**. For actual email delivery to users, you have options:

### Option A: Forward via External SMTP (SendGrid, Mailgun)

Update `/etc/msmtprc` in web container:

```bash
docker exec gettoperu-web bash -c "cat > /etc/msmtprc << 'EOF'
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt

account sendgrid
host smtp.sendgrid.net
port 587
user apikey
password your-sendgrid-api-key
from noreply@yourdomain.com

account default : sendgrid
EOF

chmod 600 /etc/msmtprc"
```

### Option B: Use Local Postfix Only

Emails stay local (good for internal notifications, testing). Update your contact form to send to internal email or admin panel.

## Firewall Configuration

```bash
# Allow HTTP/HTTPS
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## Backups

Backup your code and data:

```bash
# On droplet
cd /opt/gettoperu
tar -czf backup-$(date +%Y%m%d).tar.gz ./

# Transfer to local machine
scp -r root@your_droplet_ip:/opt/gettoperu/backup-*.tar.gz ./
```

## SSL Renewal

SSL certificates auto-renew via certbot. Check status:

```bash
sudo certbot renew --dry-run
```

## Monitoring

```bash
# View live logs
docker compose -f docker-compose.prod.yml logs -f web

# Check container health
docker compose -f docker-compose.prod.yml ps

# View resource usage
docker stats
```

## Update Website

```bash
cd /opt/gettoperu

# Pull latest code
git pull origin main

# Rebuild image (if needed)
docker compose -f docker-compose.prod.yml build --no-cache

# Restart containers
docker compose -f docker-compose.prod.yml restart web
```

## Troubleshooting

**503 Bad Gateway**
```bash
# Check if web container is running
docker compose -f docker-compose.prod.yml ps

# Restart
docker compose -f docker-compose.prod.yml restart web
```

**SSL Certificate Issues**
```bash
# Renew certificate
sudo certbot renew --force-renewal

# Restart Nginx
sudo systemctl restart nginx
```

**Email Not Sending**
```bash
# Check Postfix logs
docker compose -f docker-compose.prod.yml logs postfix

# Test email
docker exec gettoperu-web bash -c "echo 'Test' | /usr/sbin/sendmail test@example.com"
```

## Support

For issues, check:
- Nginx logs: `/var/log/nginx/access.log`
- Container logs: `docker compose logs -f`
- Certbot: `sudo certbot certificates`

