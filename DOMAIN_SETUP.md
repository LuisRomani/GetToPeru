# Domain Setup Guide for gettoperu.com

## Step 1: Verify Domain Ownership

You need to know where your domain is registered. Check your email for domain registration confirmation or visit:
- GoDaddy.com
- Namecheap.com
- Google Domains
- 1&1
- Or wherever you registered gettoperu.com

## Step 2: Get Your DigitalOcean Droplet IP

1. Log into DigitalOcean
2. Go to Droplets
3. Click on your droplet
4. Copy the **IPv4 address** (looks like: 123.45.67.89)

## Step 3: Update DNS Records

Log into your domain registrar (GoDaddy, Namecheap, etc.) and find "DNS Settings" or "Nameservers".

**You have two options:**

### Option A: Use DigitalOcean Nameservers (Recommended)

1. On DigitalOcean:
   - Go to Networking → Domains
   - Click "Add Domain"
   - Enter: gettoperu.com
   - Select your droplet

2. Copy the 3 DigitalOcean nameservers:
   - ns1.digitalocean.com
   - ns2.digitalocean.com
   - ns3.digitalocean.com

3. Go to your domain registrar (GoDaddy, Namecheap, etc.)
4. Find "Nameservers" or "DNS Settings"
5. Replace with DigitalOcean nameservers
6. Save changes

### Option B: Point Domain Directly to Droplet IP (Faster)

If your registrar doesn't support changing nameservers easily:

1. Go to your domain registrar DNS settings
2. Find the "A" record
3. Update/Create these records:

```
Name: @
Type: A
Value: your_droplet_ip (e.g., 123.45.67.89)
TTL: 3600

Name: www
Type: A
Value: your_droplet_ip (e.g., 123.45.67.89)
TTL: 3600
```

4. Save changes

## Step 4: Verify DNS Propagation

Wait 5-30 minutes for DNS to propagate, then check:

```bash
# On your computer
nslookup gettoperu.com
# Should show your droplet IP

# Or
ping gettoperu.com
# Should show your droplet IP
```

**Common DNS providers:**

### GoDaddy
1. Login to godaddy.com
2. Go to My Products
3. Click Domain name: gettoperu.com
4. Click "DNS" or "Manage"
5. Update A records or Nameservers

### Namecheap
1. Login to namecheap.com
2. Go to Domain List
3. Click Manage next to gettoperu.com
4. Go to "Nameservers" tab
5. Select "DigitalOcean Nameservers" or update manually

### Google Domains
1. Login to domains.google.com
2. Select gettoperu.com
3. Click DNS on left menu
4. Under "Custom nameservers" enter DigitalOcean nameservers
5. Save

### 1&1
1. Login to 1and1.com
2. Select Domain
3. Go to DNS Settings
4. Update nameservers or A records

## Step 5: Deploy Your Website

Once DNS is updated and verified:

```bash
# SSH into your droplet
ssh root@your_droplet_ip

# Navigate to project
cd /opt/gettoperu

# Deploy
bash deploy.sh gettoperu.com admin@gettoperu.com
```

## Step 6: Verify Website is Live

Wait a few minutes, then:

```bash
# Check DNS is working
nslookup gettoperu.com

# Visit in browser
https://gettoperu.com
```

## Common Issues

**DNS Not Resolving**
- Wait 5-30 minutes (DNS propagation takes time)
- Clear browser cache: Ctrl+Shift+Delete
- Try different DNS: `nslookup gettoperu.com 8.8.8.8`

**SSL Certificate Error**
- DNS must be working first
- Let's Encrypt needs to verify domain ownership
- Deploy script will handle this automatically

**Connection Refused**
- Check droplet is running
- Check firewall allows port 80/443
- Verify DNS points to correct IP

## Next Steps

1. Update deployment script to use your domain
2. Ensure DNS is pointing to DigitalOcean droplet
3. Run deployment: `bash deploy.sh gettoperu.com admin@gettoperu.com`
4. Test: Visit https://gettoperu.com

## Email Setup

Your domain email (admin@gettoperu.com) will be used for:
- SSL certificate renewal notifications
- Important system alerts

The contact form emails use internal Postfix SMTP (no external email needed).

## Questions About Your Domain?

**Where is gettoperu.com registered?** (Check your email)
**Do you have access to your registrar account?** (GoDaddy, Namecheap, etc.)
**Which option do you prefer?** (DigitalOcean nameservers or direct A record pointing)

Let me know and I can provide specific step-by-step instructions for your registrar.
