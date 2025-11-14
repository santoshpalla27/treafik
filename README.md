# Complete Production-Grade Traefik v3 + Let's Encrypt + Portainer Setup

This repository contains a complete, production-grade setup for Traefik v3, Let's Encrypt, and Portainer using Docker Compose. It is designed to be secure, efficient, and easily configurable through environment variables.

## 1. 📁 Directory Structure

```
traefik-stack/
├── docker-compose.yml
├── .env
├── traefik/
│   ├── traefik.yml
│   ├── dynamic.yml
│   └── acme.json
└── README.md
```

## 2. 🚀 Deployment Commands

### Step 1: Create Directory Structure

```bash
# Create project directory
mkdir -p traefik-stack/traefik
cd traefik-stack

# Create necessary files
touch docker-compose.yml .env
touch traefik/traefik.yml traefik/dynamic.yml traefik/acme.json

# Set correct permissions for acme.json
chmod 600 traefik/acme.json
```

### Step 2: Generate Bcrypt Password Hash

**Method 1: Using Docker (Recommended)**
```bash
# Replace 'YourPasswordHere' with your actual password
docker run --rm httpd:alpine htpasswd -nbB admin 'YourPasswordHere' | cut -d ":" -f 2
```

**Method 2: Using htpasswd (if installed locally)**
```bash
htpasswd -nbB admin 'YourPasswordHere' | cut -d ":" -f 2
```

**Important:**
- Copy the output and paste it into `.env` as `BASIC_AUTH_HASH`.
- Escape dollar signs by doubling them: `$` → `$$` (required in .env files).
- Example: `$2y$05$abc...` becomes `$$2y$$05$$abc...`

### Step 3: Configure Environment Variables

Edit the `.env` file with your actual values:
```bash
nano .env
```
Update these values:
- `TRAEFIK_DOMAIN` - Your Traefik dashboard domain
- `PORTAINER_DOMAIN` - Your Portainer domain
- `LETSENCRYPT_EMAIL` - Your valid email for Let's Encrypt
- `BASIC_AUTH_HASH` - Generated bcrypt hash (with escaped `$$`)

### Step 4: DNS Configuration

Before deploying, configure DNS A records:
```
traefik.example.com    → Your_Server_IP
portainer.example.com  → Your_Server_IP
```
Verify DNS propagation:
```bash
nslookup traefik.example.com
nslookup portainer.example.com
```

### Step 5: Create Docker Network
```bash
docker network create proxy
```

### Step 6: Deploy the Stack
```bash
# Validate compose file
docker compose config

# Deploy in detached mode
docker compose up -d

# View logs
docker compose logs -f

# Check specific service logs
docker compose logs -f traefik
docker compose logs -f portainer
```

### Step 7: Verify Deployment
```bash
# Check running containers
docker compose ps

# Check Traefik logs for certificate acquisition
docker compose logs traefik | grep -i certificate

# Verify acme.json has been populated
ls -lah traefik/acme.json
cat traefik/acme.json | jq .  # If you have jq installed
```

### Step 8: Access Services
- **Traefik Dashboard:** `https://traefik.example.com`
- **Portainer:** `https://portainer.example.com`

Login credentials:
- **Username:** `admin` (or your configured `BASIC_AUTH_USER`)
- **Password:** Your configured password (not the hash)

## 3. 🔒 Production Hardening Notes

### Security Enhancements

1.  **Disable Traefik Dashboard in Production (Optional)**
    If you don't need the dashboard:
    ```yaml
    # In traefik.yml, change:
    api:
      dashboard: false
    ```
    And remove the dashboard labels from `docker-compose.yml`.

2.  **Enable IP Whitelisting**
    Restrict access to Traefik dashboard and Portainer:
    ```
    # In .env, add:
    WHITELIST_IPS=YOUR_OFFICE_IP/32,YOUR_HOME_IP/32
    ```
    ```yaml
    # In docker-compose.yml, update labels:
    - "traefik.http.routers.traefik-dashboard.middlewares=traefik-auth,securityHeaders,ip-whitelist"
    - "traefik.http.routers.portainer.middlewares=portainer-auth,securityHeaders,ip-whitelist"
    ```
    ```yaml
    # In dynamic.yml, uncomment and configure:
    ip-whitelist:
      ipWhiteList:
        sourceRange:
          - "${WHITELIST_IPS}"
    ```

3.  **Enable Rate Limiting**
    Protect against brute-force attacks:
    ```
    # In .env:
    RATE_LIMIT_AVERAGE=100
    RATE_LIMIT_BURST=50
    ```
    In `dynamic.yml`, uncomment the `rate-limit` middleware. In `docker-compose.yml` labels, add:
    ```yaml
    - "traefik.http.routers.traefik-dashboard.middlewares=traefik-auth,securityHeaders,rate-limit"
    ```

4.  **Use Strong Authentication**
    ```bash
    # Generate a strong password (Linux/Mac)
    openssl rand -base64 32
    ```

5.  **Restrict Docker Socket Access**
    For enhanced security, use a Docker Socket Proxy.

6.  **Enable Fail2Ban (Host Level)**
    Create `/etc/fail2ban/filter.d/traefik-auth.conf`:
    ```
    [Definition]
    failregex = ^<HOST> - \S+ \[.+?\] \".*\" 401 .+$ 
    ignoreregex = 
    ```
    Create `/etc/fail2ban/jail.d/traefik.conf`:
    ```
    [traefik-auth]
    enabled = true
    port = http,https
    filter = traefik-auth
    logpath = /var/lib/docker/volumes/traefik-stack_traefik_letsencrypt/_data/access.log
    maxretry = 5
    bantime = 3600
    findtime = 600
    ```

7.  **Regular Updates**
    ```bash
    # Update images
    docker compose pull

    # Restart with new images
    docker compose up -d

    # Clean up old images
    docker image prune -a
    ```

8.  **Backup Certificates**
    ```bash
    #!/bin/bash
    BACKUP_DIR="/backups/traefik"
    DATE=$(date +%Y%m%d_%H%M%S)

    mkdir -p $BACKUP_DIR
    cp traefik/acme.json $BACKUP_DIR/acme_$DATE.json
    chmod 600 $BACKUP_DIR/acme_$DATE.json

    # Keep only last 7 backups
    ls -t $BACKUP_DIR/acme_*.json | tail -n +8 | xargs rm -f
    ```

9.  **Monitor Certificate Expiry**
    ```bash
    docker compose exec traefik cat /letsencrypt/acme.json | jq '.letsencrypt.Certificates[] | {domain: .domain.main, notAfter: .certificate | @base64d | @text | fromjson | .notAfter}'
    ```

10. **Enable Prometheus Metrics (Optional)**
    Uncomment the metrics section in `traefik.yml` and add Prometheus to `docker-compose.yml`.

## 4. 📊 Monitoring & Troubleshooting

- **Check Container Status:** `docker compose ps`, `docker compose logs -f traefik`
- **Verify Traefik Configuration:** `docker compose logs traefik | grep -i error`
- **Test HTTPS Certificates:** `openssl s_client -connect traefik.example.com:443 -servername traefik.example.com < /dev/null`
- **Debug DNS Issues:** `nslookup traefik.example.com`

## 5. 🎯 Quick Reference Commands
```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# Restart a specific service
docker compose restart traefik

# View real-time logs
docker compose logs -f

# Update and restart
docker compose pull && docker compose up -d

# Remove everything (including volumes)
docker compose down -v
```

## 6. 📁 Complete File Checklist
- ✅ `docker-compose.yml`
- ✅ `.env` (DO NOT COMMIT TO GIT)
- ✅ `traefik/traefik.yml`
- ✅ `traefik/dynamic.yml`
- ✅ `traefik/acme.json` (chmod 600)
- ✅ `.gitignore`

## 7. 🎉 Success Checklist
After deployment, verify:
- Traefik and Portainer containers are running.
- DNS records are configured correctly.
- HTTPS redirects work.
- Let's Encrypt certificates are issued.
- Traefik dashboard and Portainer are accessible with auth.
- Security headers are present.
- `acme.json` has correct permissions (600).
- Logs show no errors.

## 🎓 Additional Resources
- [Traefik v3 Documentation](https://doc.traefik.io/traefik/v3.0/)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
- [Portainer Documentation](https://docs.portainer.io/)
- [Docker Compose Reference](https://docs.docker.com/compose/reference/)
