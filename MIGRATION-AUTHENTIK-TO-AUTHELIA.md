# Migration Guide: Authentik → Authelia

This guide will help you migrate from Authentik to Authelia for SSO authentication.

## ✅ What's Been Done

All configuration files have been created and updated:
- ✅ Authelia service created (`services/authelia/`)
- ✅ Docker Compose configuration ready
- ✅ Authelia configuration files created
- ✅ Caddyfile updated with Authelia forward auth
- ✅ All startup scripts updated
- ✅ Documentation complete

## 🔧 Pre-Migration Checklist

### 1. Generate Secrets

Run these commands and save the output:

```bash
# Generate JWT Secret
echo "AUTHELIA_JWT_SECRET=$(openssl rand -base64 64 | tr -d '\n')"

# Generate Session Secret  
echo "AUTHELIA_SESSION_SECRET=$(openssl rand -base64 64 | tr -d '\n')"

# Generate Encryption Key
echo "AUTHELIA_ENCRYPTION_KEY=$(openssl rand -base64 64 | tr -d '\n')"
```

### 2. Add Secrets to .env

Edit `/opt/docker/homelab/.env` and add:

```bash
# Authelia Configuration
PORT_AUTHELIA=9091

# Authelia Secrets (paste generated values here)
AUTHELIA_JWT_SECRET=<paste-jwt-secret>
AUTHELIA_SESSION_SECRET=<paste-session-secret>
AUTHELIA_ENCRYPTION_KEY=<paste-encryption-key>
```

### 3. Backup Authentik (Optional but Recommended)

```bash
# Backup Authentik database
docker exec authentik_db pg_dump -U authentik authentik > ~/authentik_backup_$(date +%Y%m%d).sql

# Backup Redis
docker exec authentik_redis redis-cli SAVE
sudo cp /mnt/storage/db/authentik-redis/dump.rdb ~/authentik_redis_backup_$(date +%Y%m%d).rdb

echo "✅ Backups created in home directory"
```

### 4. Export User List

Document your current Authentik users so you can recreate them in Authelia:
- Usernames
- Display names
- Email addresses
- Groups

## 🚀 Migration Steps

### Step 1: Stop Current Services

```bash
cd /opt/docker/homelab/services/public
docker compose down

cd ../authentik
docker compose down

# Verify they're stopped
docker ps | grep -E "authentik|caddy"
```

### Step 2: Create Directories

```bash
sudo mkdir -p /srv/docker/authelia
sudo mkdir -p /mnt/storage/db/authelia-redis
sudo chown -R $USER:docker /srv/docker/authelia
sudo chown -R $USER:docker /mnt/storage/db/authelia-redis
```

### Step 3: Create Network

```bash
docker network create authelia-net
```

### Step 4: Configure Users

Generate password hash for your admin user:

```bash
docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password 'your-admin-password-here'
```

Edit `services/authelia/staticconfig/users_database.yml`:

```yaml
users:
  admin:
    displayname: "Your Name"
    password: "$argon2id$v=19$m=65536,t=3,p=4$PASTE_HASH_HERE"
    email: your@email.com
    groups:
      - admins
      - users
```

Repeat for all users you need to migrate.

### Step 5: Create .env Symlink for Authelia

```bash
cd /opt/docker/homelab/services/authelia
ln -sf ../../.env .env
```

### Step 6: Start Authelia

```bash
cd /opt/docker/homelab/services/authelia
docker compose up -d

# Watch logs for any errors
docker logs authelia -f
```

Wait for Authelia to be fully started (should see "Authelia is now listening" message).

### Step 7: Test Authelia

```bash
# Test that Authelia is responding
curl -I http://localhost:9091

# Should return HTTP 200 or 302
```

### Step 8: Start Caddy

```bash
cd /opt/docker/homelab/services/public
docker compose up -d

# Check logs
docker logs caddy -f
```

### Step 9: Test Authentication

1. Open a browser and navigate to one of your protected services:
   - `https://home.yourdomain.com` (Homepage)
   - `https://ha.yourdomain.com` (Home Assistant)
   - `https://request.yourdomain.com` (Jellyseerr)

2. You should be redirected to `https://auth.yourdomain.com`

3. Log in with the credentials you configured

4. After successful login, you should be redirected back to the service

5. Test 2FA setup:
   - Click "Register device" under Two-Factor Authentication
   - Scan QR code with authenticator app
   - Confirm with code

### Step 10: Verify All Services

Test access to all protected services:
- ✅ Main domain
- ✅ Homepage Dashboard
- ✅ Home Assistant  
- ✅ Jellyseerr

## 🧹 Post-Migration Cleanup

### Remove Authentik (After Confirming Everything Works)

```bash
# Remove Authentik service directory
rm -rf /opt/docker/homelab/services/authentik

# Remove network
docker network rm authentik-net

# Optional: Remove Authentik data (keep backups!)
# sudo rm -rf /srv/docker/authentik
# sudo rm -rf /mnt/storage/db/authentik-postgres
# sudo rm -rf /mnt/storage/db/authentik-redis
```

### Clean Up .env (Optional)

Remove old Authentik variables from `.env`:
- `PORT_AUTHENTIK_HTTP`
- `PORT_AUTHENTIK_HTTPS`
- `AUTHENTIK_DB_USER`
- `AUTHENTIK_DB_NAME`
- `AUTHENTIK_DB_PASSWORD`
- `AUTHENTIK_SECRET_KEY`

## 🔄 Rollback Plan

If you encounter issues and need to rollback:

```bash
# Stop Authelia and Caddy
cd /opt/docker/homelab/services/authelia
docker compose down

cd ../public
docker compose down

# Restore Authentik
cd ../authentik
docker network create authentik-net
docker compose up -d

# Wait for Authentik to start
sleep 20

# Revert Caddyfile changes
cd ../public/staticconfig/caddy
git checkout Caddyfile  # if using git
# OR manually replace authelia references back to authentik

# Start Caddy
cd ../../
docker compose up -d
```

## 📊 Comparison: Before & After

### Resource Usage
- **Before**: 4 containers (Server, Worker, PostgreSQL, Redis)
- **After**: 2 containers (Authelia, Redis)
- **Expected Savings**: ~200-300MB RAM, lower CPU usage

### Port Changes
- **Before**: Port 9000 (Authentik)
- **After**: Port 9091 (Authelia)

### Configuration
- **Before**: Web UI configuration
- **After**: YAML file configuration

## 🔧 Troubleshooting

### Issue: Can't access protected services

**Check Authelia logs:**
```bash
docker logs authelia
```

**Verify forward auth is working:**
```bash
curl -v http://localhost:9091/api/verify
```

### Issue: Redirect loop

**Check:**
- Session domain in `configuration.yml` matches your domain
- Caddy snippet is correctly configured
- Time is synced on server (important for JWT tokens)

### Issue: Users can't log in

**Verify:**
- Password hash is correct in `users_database.yml`
- User exists in the file
- File permissions are correct: `chmod 644 staticconfig/users_database.yml`

### Issue: Caddy won't start

**Check:**
```bash
docker logs caddy

# Validate Caddyfile syntax
docker exec caddy caddy validate --config /etc/caddy/Caddyfile
```

## 📚 Next Steps

After successful migration:

1. **Set up 2FA** for all users
2. **Test all protected services** thoroughly
3. **Document any service-specific issues**
4. **Consider LDAP** if you have many users (see Authelia docs)
5. **Set up OIDC** for services like Jellyfin (optional)
6. **Configure email notifications** (currently using file notifier)

## 📖 Additional Resources

- [Authelia Documentation](https://www.authelia.com/)
- [Authelia with Caddy](https://www.authelia.com/integration/proxies/caddy/)
- [Access Control Configuration](https://www.authelia.com/configuration/security/access-control/)
- [User Database Format](https://www.authelia.com/configuration/first-factor/file/)

## ✅ Migration Checklist

- [ ] Secrets generated and added to .env
- [ ] Authentik backed up
- [ ] User list documented
- [ ] Directories created
- [ ] Network created
- [ ] Users configured in users_database.yml
- [ ] .env symlink created
- [ ] Authelia started successfully
- [ ] Caddy started successfully
- [ ] Login tested on protected services
- [ ] 2FA configured and tested
- [ ] All services verified
- [ ] Old Authentik service removed
- [ ] Backups kept in safe location

---

**Migration Date**: ________________

**Performed By**: ________________

**Notes**: ________________





