# Traefik + Portainer Production Setup

Production-ready Traefik reverse proxy with Portainer container management.

## Features

- ✅ Automatic HTTPS with Let's Encrypt
- ✅ HTTP to HTTPS redirect
- ✅ Security headers (HSTS, CSP, etc.)
- ✅ Basic authentication for Traefik dashboard
- ✅ Docker container management with Portainer
- ✅ Custom landing page
- ✅ Health checks
- ✅ Compression
- ✅ Production-grade TLS configuration

## Prerequisites

- Docker &amp; Docker Compose installed
- Domain name with DNS configured
- Ports 80 and 443 open in firewall

## Quick Start

1. **Clone and configure:**
   ```bash
   cp .env.example .env
   nano .env  # Edit with your details
Generate password hash:

docker run --rm httpd:alpine htpasswd -nbB admin 'YourPassword' | cut -d ":" -f 2 | sed 's/\$/\\$/g'
Deploy:

docker compose up -d
Check logs:

docker logs traefik -f
Access services:

Landing: https://yourdomain.com
Traefik: https://traefik.yourdomain.com
Portainer: https://portainer.yourdomain.com
Configuration
Environment Variables
See
.env.example
for all available options.

Update Password
Generate new hash
Update
BASIC_AUTH_HASH
in
.env
Update hash in
traefik/dynamic.yml
Restart:
docker compose restart traefik
Maintenance
View logs:
docker logs traefik
docker logs portainer
Restart services:
docker compose restart
Update containers:
docker compose pull
docker compose up -d
Backup certificates:
docker cp traefik:/letsencrypt/acme.json ./backup/
Security Checklist
 Changed default passwords
 Configured firewall (ports 80, 443)
 Set up IP whitelist (optional)
 Enabled rate limiting (optional)
 Regular security updates
 Monitoring and alerts configured
Troubleshooting
Certificate issues:
docker logs traefik | grep -i cert
Reset certificates:
docker compose down
docker volume rm traefik_letsencrypt
docker compose up -d
Support
For issues, check:

Traefik docs: https://doc.traefik.io/traefik/
Portainer docs: https://docs.portainer.io/
License
MIT License 
