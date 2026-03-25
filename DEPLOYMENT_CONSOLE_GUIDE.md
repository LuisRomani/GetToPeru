# GetToPeru Deployment Guide - DigitalOcean Console (Step-by-Step)

## Your Details
- **Domain**: gettoperu.com
- **Droplet IP**: 143.198.114.97
- **Admin Email**: admin@gettoperu.com

## Part 1: Configure GoDaddy DNS

### Step 1.1: Log into GoDaddy

1. Go to https://www.godaddy.com
2. Click "Sign In" (top right)
3. Enter your email and password
4. You should see "My Products"

### Step 1.2: Find Your Domain

1. In "My Products", find **Domains** section
2. Look for **gettoperu.com** in the list
3. Click the three dots (...) next to gettoperu.com
4. Click **"Manage DNS"** or **"Manage"**

### Step 1.3: Update DNS - Option A (Recommended)

**Using DigitalOcean Nameservers:**

1. In GoDaddy, click the **"Nameservers"** section (or similar)
2. Click **"Change"** or **"Change to custom nameservers"**
3. Delete existing nameservers
4. Add these three nameservers:
   ```
   ns1.digitalocean.com
   ns2.digitalocean.com
   ns3.digitalocean.com
   ```
5. Click **"Save"** at the bottom

**OR Step 1.3 Alternative: Option B (Direct A Records)**

If you can't find Nameservers option, use A Records:

1. In GoDaddy DNS settings, find **"A"** records
2. Look for a record with Name = `@` (or empty)
3. Change the Value to: `143.198.114.97`
4. Click **"Save"**
5. Look for a record with Name = `www`
6. Change the Value to: `143.198.114.97`
7. Click **"Save"**

**Wait 5-10 minutes** for DNS to update.

---

## Part 2: Prepare Files on Your Local Computer

### Step 2.1: Create Deployment Files

On your **local computer**, in your GetToPeru project folder, create/verify these files:

#### File 1: `install-docker.sh`
```bash
#!/bin/bash
set -e
sudo apt-get update
sudo apt-get upgrade -y
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo apt-get install -y git certbot
echo "Docker installed successfully!"
```

#### File 2: `deploy.sh`
```bash
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
```

#### File 3: `docker-compose.prod.yml`
```yaml
version: '3.8'

services:
  web:
    image: gettoperu:latest
    container_name: gettoperu-web
    ports:
      - "127.0.0.1:80:80"
    volumes:
      - ./public_html:/var/www/html
    environment:
      - PHP_MEMORY_LIMIT=512M
      - PHP_MAX_EXECUTION_TIME=120
    restart: always
    networks:
      - gettoperu-network
    depends_on:
      - postfix
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3

  postfix:
    image: boky/postfix:latest
    container_name: gettoperu-postfix
    hostname: mail.gettoperu.local
    environment:
      MAILNAME: gettoperu.local
      ALLOWED_SENDER_DOMAINS: gettoperu.local
    volumes:
      - postfix_data:/var/spool/postfix
    restart: always
    networks:
      - gettoperu-network

networks:
  gettoperu-network:
    driver: bridge

volumes:
  postfix_data:
    driver: local
```

---

## Part 3: Upload Files to Droplet via Console

### Step 3.1: Open DigitalOcean Console

1. Go to https://cloud.digitalocean.com
2. Click **"Droplets"** (left menu)
3. Click on your droplet (143.198.114.97)
4. Click **"Console"** button (top right)
5. Wait for console to load (black screen with prompt)
6. You should see: `root@ubuntu-droplet-name:~#`

### Step 3.2: Create Project Directory

In the console, type:

```bash
mkdir -p /opt/gettoperu
cd /opt/gettoperu
pwd
```

You should see: `/opt/gettoperu`

### Step 3.3: Create Dockerfile

In the console, type:

```bash
cat > Dockerfile << 'EOF'
FROM php:8.2-apache AS base

WORKDIR /var/www/html

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    libonig-dev \
    libxml2-dev \
    libicu-dev \
    curl \
    git \
    msmtp \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    mbstring \
    xml \
    soap \
    && docker-php-ext-enable pdo pdo_mysql pdo_pgsql mbstring xml soap

RUN a2enmod rewrite headers ssl

RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html|g' /etc/apache2/sites-enabled/000-default.conf

COPY --chown=www-data:www-data . .

RUN { \
    echo 'memory_limit = 256M'; \
    echo 'max_execution_time = 60'; \
    echo 'upload_max_filesize = 100M'; \
    echo 'post_max_size = 100M'; \
    echo 'error_log = /var/log/php-error.log'; \
    echo 'display_errors = Off'; \
    echo 'log_errors = On'; \
    echo 'sendmail_path = "/usr/sbin/sendmail -t -i"'; \
    } > /usr/local/etc/php/conf.d/production.ini

RUN mkdir -p /var/log/apache2 && \
    chown -R www-data:www-data /var/www/html /var/log/apache2 && \
    { \
    echo 'defaults'; \
    echo 'auth off'; \
    echo 'tls off'; \
    echo 'domain gettoperu.local'; \
    echo 'host postfix'; \
    echo 'port 25'; \
    echo 'from noreply@gettoperu.local'; \
    echo ''; \
    echo 'account default'; \
    echo 'host postfix'; \
    echo 'port 25'; \
    echo 'from noreply@gettoperu.local'; \
    } > /etc/msmtprc && \
    chmod 644 /etc/msmtprc && \
    { \
    echo '#!/bin/bash'; \
    echo 'exec /usr/bin/msmtp "$@"'; \
    } > /usr/sbin/sendmail && \
    chmod 755 /usr/sbin/sendmail

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

EXPOSE 80

CMD ["apache2-foreground"]
EOF
```

Verify it worked:
```bash
cat Dockerfile
```

You should see the Dockerfile content.

### Step 3.4: Create docker-compose.prod.yml

```bash
cat > docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  web:
    image: gettoperu:latest
    container_name: gettoperu-web
    ports:
      - "127.0.0.1:80:80"
    volumes:
      - ./public_html:/var/www/html
    environment:
      - PHP_MEMORY_LIMIT=512M
      - PHP_MAX_EXECUTION_TIME=120
    restart: always
    networks:
      - gettoperu-network
    depends_on:
      - postfix
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3

  postfix:
    image: boky/postfix:latest
    container_name: gettoperu-postfix
    hostname: mail.gettoperu.local
    environment:
      MAILNAME: gettoperu.local
      ALLOWED_SENDER_DOMAINS: gettoperu.local
    volumes:
      - postfix_data:/var/spool/postfix
    restart: always
    networks:
      - gettoperu-network

networks:
  gettoperu-network:
    driver: bridge

volumes:
  postfix_data:
    driver: local
EOF
```

Verify:
```bash
cat docker-compose.prod.yml
```

### Step 3.5: Create .dockerignore

```bash
cat > .dockerignore << 'EOF'
.git/
.gitignore
.github/
vendor/
node_modules/
composer.lock
package-lock.json
yarn.lock
.env
.env.local
.env.*.local
.DS_Store
.vscode/
.idea/
*.swp
*.swo
*~
.sublime-project
.sublime-workspace
dist/
build/
.cache/
*.cache
Thumbs.db
.AppleDouble
docker-compose.override.yml
*.log
logs/
tmp/
temp/
DEPLOYMENT_GUIDE.md
DOMAIN_SETUP.md
DEPLOYMENT_CHECKLIST.md
install-docker.sh
deploy.sh
EOF
```

### Step 3.6: Clone Your Project

```bash
git clone https://github.com/LuisRomani/GetToPeru.git temp
cp -r temp/* .
cp -r temp/.git* .
rm -rf temp
ls -la
```

You should see your project files (public_html/, index.html, etc.)

---

## Part 4: Install Docker

In the console:

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt-get install -y git
```

Wait for installation to complete (2-3 minutes).

---

## Part 5: Build and Deploy

### Step 5.1: Build Docker Image

```bash
cd /opt/gettoperu
sudo docker build -t gettoperu:latest .
```

Wait for build to complete (5-10 minutes). You'll see:
```
Successfully built [hash]
Successfully tagged gettoperu:latest
```

### Step 5.2: Start Containers

```bash
sudo docker compose -f docker-compose.prod.yml up -d
```

Check status:
```bash
sudo docker compose -f docker-compose.prod.yml ps
```

You should see:
```
gettoperu-web       ... Up
gettoperu-postfix   ... Up
```

---

## Part 6: Setup Nginx & SSL

### Step 6.1: Install Nginx and Certbot

```bash
sudo apt-get update
sudo apt-get install -y nginx certbot python3-certbot-nginx
```

### Step 6.2: Generate SSL Certificate

```bash
sudo certbot certonly \
    --standalone \
    --non-interactive \
    --agree-tos \
    --email admin@gettoperu.com \
    -d gettoperu.com
```

Wait for certificate generation (30 seconds).

### Step 6.3: Configure Nginx

```bash
sudo tee /etc/nginx/sites-available/gettoperu.com > /dev/null << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name gettoperu.com www.gettoperu.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name gettoperu.com www.gettoperu.com;

    ssl_certificate /etc/letsencrypt/live/gettoperu.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/gettoperu.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://127.0.0.1:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
```

### Step 6.4: Enable Nginx Site

```bash
sudo ln -sf /etc/nginx/sites-available/gettoperu.com /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

### Step 6.5: Setup SSL Auto-Renewal

```bash
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

---

## Part 7: Verify Deployment

In the console:

```bash
# Check containers
sudo docker compose -f docker-compose.prod.yml ps

# Check Nginx
sudo systemctl status nginx

# Check SSL
sudo certbot certificates
```

All should show as running/active.

---

## Part 8: Test Website

Wait 5-10 minutes for DNS to fully propagate, then:

1. Open browser
2. Go to **https://gettoperu.com**
3. You should see your website!

---

## Troubleshooting

**DNS Not Working?**
```bash
nslookup gettoperu.com
# Should show 143.198.114.97
```

**Containers Not Running?**
```bash
sudo docker compose -f docker-compose.prod.yml logs web
```

**SSL Issues?**
```bash
sudo certbot certificates
```

**Reset Everything?**
```bash
cd /opt/gettoperu
sudo docker compose -f docker-compose.prod.yml down
sudo docker compose -f docker-compose.prod.yml up -d
```

---

## Summary

✅ DNS configured in GoDaddy  
✅ Files uploaded to droplet  
✅ Docker installed  
✅ Docker image built  
✅ Containers running  
✅ Nginx configured  
✅ SSL certificate installed  
✅ Website live at https://gettoperu.com  

**Your website is now live!**

Contact form emails use internal Postfix SMTP - they won't leave the server but are available for testing.

