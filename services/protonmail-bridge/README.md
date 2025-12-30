# Proton Mail Bridge

Docker container for Proton Mail Bridge, providing SMTP and IMAP access to your Proton Mail account.

## Purpose

Proton Mail Bridge allows you to:
- Send emails via SMTP from services like Authelia
- Access Proton Mail via IMAP in email clients
- Maintain end-to-end encryption with Proton Mail

## Initial Setup

### 1. Create Required Directories

```bash
sudo mkdir -p /srv/docker/protonmail-bridge
sudo chown -R $USER:docker /srv/docker/protonmail-bridge
```

### 2. Create Network

```bash
docker network create proton-bridge-net
```

### 3. Create .env Symlink

```bash
cd /opt/docker/homelab/services/protonmail-bridge
ln -sf ../../.env .env
```

### 4. Start the Service

```bash
docker compose up -d
```

### 5. Login to Your Proton Account

**This is interactive** - you'll need to log in to your Proton Mail account:

```bash
docker exec -it protonmail-bridge /protonmail/bridge-wrapper
```

**Commands to use:**

1. **Login:**
   ```
   login
   ```
   - Enter your Proton email address
   - Enter your Proton password
   - Complete 2FA if enabled

2. **Get Bridge Credentials:**
   ```
   info
   ```
   This shows your:
   - **SMTP address**: `protonmail-bridge:25` (for Docker services)
   - **Bridge password**: Copy this! It's different from your Proton password
   
3. **Exit:**
   ```
   exit
   ```

### 6. Save Your Bridge Credentials

After running `info`, you'll see something like:

```
Account: youremail@proton.me
Username: youremail@proton.me
Password: xxxxxxxxxxxx  <-- COPY THIS!
SMTP: protonmail-bridge:25
```

**Save these for configuring other services (like Authelia)!**

## Using with Other Services

### For Authelia

In Authelia's docker-compose.yml:

1. **Add the Bridge network:**
   ```yaml
   networks:
     - authelia-net
     - caddy-net
     - proton-bridge-net  # Add this
   ```

2. **Add network definition:**
   ```yaml
   networks:
     proton-bridge-net:
       name: proton-bridge-net
       external: true
   ```

3. **Configure SMTP in .env:**
   ```bash
   AUTHELIA_NOTIFIER_SMTP_USERNAME=your-email@proton.me
   AUTHELIA_NOTIFIER_SMTP_PASSWORD=bridge-password-from-info-command
   AUTHELIA_NOTIFIER_SMTP_SENDER=Authelia <your-email@proton.me>
   ```

4. **Set SMTP address in Authelia's docker-compose:**
   ```yaml
   AUTHELIA_NOTIFIER_SMTP_ADDRESS: smtp://protonmail-bridge:25
   AUTHELIA_NOTIFIER_SMTP_DISABLE_REQUIRE_TLS: "true"
   AUTHELIA_NOTIFIER_SMTP_DISABLE_STARTTLS: "true"
   ```

## Management Commands

### View Logs
```bash
docker logs protonmail-bridge -f
```

### Access Bridge CLI
```bash
docker exec -it protonmail-bridge /protonmail/bridge-wrapper
```

**Useful CLI commands:**
- `list` - Show configured accounts
- `info` - Show account details and credentials
- `change mode` - Toggle between split/combined address mode
- `logout` - Logout from account
- `exit` - Exit CLI

### Restart Bridge
```bash
docker restart protonmail-bridge
```

### Stop/Start Service
```bash
cd /opt/docker/homelab/services/protonmail-bridge
docker compose down
docker compose up -d
```

## Troubleshooting

### Bridge Won't Start
```bash
# Check logs
docker logs protonmail-bridge

# Recreate with fresh data
docker compose down
sudo rm -rf /srv/docker/protonmail-bridge/*
docker compose up -d
# Then login again
```

### Need to Re-login
```bash
docker exec -it protonmail-bridge /protonmail/bridge-wrapper
# Type: login
```

### Connection Issues from Other Services
```bash
# Test connectivity
docker exec authelia nc -zv protonmail-bridge 25

# Verify networks
docker network inspect proton-bridge-net
```

### Check Bridge Status
```bash
docker exec -it protonmail-bridge /protonmail/bridge-wrapper
# Type: info
# Then: exit
```

## Security Notes

- Bridge ports (1025, 1143) are only exposed to localhost on the host
- Docker services access Bridge via internal Docker network (port 25/143)
- Bridge password is auto-generated and different from your Proton password
- Credentials are stored in `/srv/docker/protonmail-bridge`
- Keep this directory backed up to avoid re-logging in

## Architecture

```
┌─────────────┐         ┌──────────────────┐         ┌─────────────┐
│   Service   │         │ Protonmail-Bridge│         │ Proton Mail │
│  (Authelia) │────────▶│    Container     │────────▶│   Servers   │
│             │ SMTP:25 │                  │ Internet│             │
└─────────────┘         └──────────────────┘         └─────────────┘
      │                         │
      │                         │
      └─────────┬───────────────┘
                │
        ┌───────▼───────────┐
        │ proton-bridge-net │
        │  Docker Network   │
        └───────────────────┘
```

## Backup & Restore

### Backup
```bash
# Stop bridge
docker compose down

# Backup data
sudo tar -czf protonmail-bridge-backup-$(date +%Y%m%d).tar.gz /srv/docker/protonmail-bridge

# Start bridge
docker compose up -d
```

### Restore
```bash
# Stop bridge
docker compose down

# Restore data
sudo tar -xzf protonmail-bridge-backup-YYYYMMDD.tar.gz -C /

# Start bridge
docker compose up -d
```

## Notes

- You only need to login once - credentials persist
- If you change your Proton password, you may need to re-login to Bridge
- Bridge updates happen automatically via the Docker image
- Split mode: Each address gets separate SMTP/IMAP credentials
- Combined mode: All addresses share one SMTP/IMAP credential (default)

## Resources

- [Bridge Docker Image](https://github.com/shenxn/protonmail-bridge-docker)
- [Official Proton Bridge](https://proton.me/mail/bridge)
- [Proton Bridge CLI Guide](https://proton.me/support/bridge-cli-guide)




