# GetToPeru Deployment Checklist for gettoperu.com

## Pre-Deployment

- [ ] Domain: **gettoperu.com** registered
- [ ] Domain registrar account ready (GoDaddy, Namecheap, etc.)
- [ ] DigitalOcean account created
- [ ] SSH key generated for droplet access

## DigitalOcean Setup

- [ ] Created Ubuntu 22.04 Droplet ($5/month)
- [ ] Copied Droplet IPv4 address: _______________
- [ ] Installed Docker: `bash install-docker.sh`
- [ ] Cloned repository to `/opt/gettoperu`

## Domain Configuration

- [ ] **Option A (Recommended)**: Added domain to DigitalOcean nameservers
  - [ ] Copied DigitalOcean nameservers (ns1, ns2, ns3)
  - [ ] Updated registrar with DigitalOcean nameservers
  - OR
- [ ] **Option B**: Updated A records in registrar
  - [ ] A record @ → your droplet IP
  - [ ] A record www → your droplet IP

- [ ] Verified DNS propagation: `nslookup gettoperu.com`
- [ ] Confirmed IP shows your droplet IP

## Deployment

- [ ] Updated deploy.sh with correct domain
- [ ] Ran: `bash deploy.sh gettoperu.com admin@gettoperu.com`
- [ ] Waited for SSL certificate generation (2-3 minutes)
- [ ] Containers running: `docker compose -f docker-compose.prod.yml ps`

## Testing

- [ ] HTTP redirects to HTTPS: `curl -I http://gettoperu.com`
- [ ] HTTPS works: `curl -I https://gettoperu.com`
- [ ] Website loads: https://gettoperu.com ✓
- [ ] Contact form works: Fill and submit
- [ ] Emails sending: Check logs

## Post-Deployment

- [ ] Email notifications set up
- [ ] Backups scheduled
- [ ] Monitoring enabled
- [ ] SSL auto-renewal confirmed

## Troubleshooting Commands

```bash
# SSH into droplet
ssh root@your_droplet_ip

# Check containers
docker compose -f docker-compose.prod.yml ps

# View logs
docker compose -f docker-compose.prod.yml logs -f web

# Check DNS
nslookup gettoperu.com

# Check SSL
sudo certbot certificates
```

## Contact Info

- **Domain**: gettoperu.com
- **Admin Email**: admin@gettoperu.com
- **Droplet IP**: _______________
- **SSL Auto-Renewal**: Enabled via Certbot

---

**Need help?** Check the detailed guides:
- `DEPLOYMENT_GUIDE.md` - Full deployment instructions
- `DOMAIN_SETUP.md` - Step-by-step domain configuration
