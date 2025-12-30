# ✅ Ready to Migrate!

## What's Been Prepared

### ✅ Configuration Files
- `docker-compose.yml` - Authelia service definition
- `staticconfig/configuration.yml` - Authelia configuration  
- `staticconfig/users_database.yml` - Admin user configured (username: admin, password: changeme)

### ✅ Updated Files
- `services/public/staticconfig/caddy/Caddyfile` - Authelia forward auth
- `scripts/start-public-stack.sh` - Updated for Authelia
- `scripts/stop-public-stack.sh` - Updated for Authelia
- `scripts/start-all.sh` - Updated references

### ✅ Secrets Generated
Your unique secrets have been generated and saved in:
- `GENERATED-SECRETS.env`

### ✅ Migration Script Created
A complete automated migration script is ready:
- `complete-migration.sh`

---

## 🚀 Run The Migration

Open a terminal and run:

```bash
cd /home/coenw/Dev/homelab-docker/services/authelia
./complete-migration.sh
```

This script will:
1. ✅ Add secrets to /opt/docker/homelab/.env
2. ✅ Create required directories
3. ✅ Create Docker network
4. ✅ Create .env symlink
5. ✅ Stop Authentik and Caddy
6. ✅ Start Authelia
7. ✅ Start Caddy
8. ✅ Verify everything is running

**Estimated time:** 2-3 minutes
**Downtime:** ~30 seconds

---

## 🔐 Initial Login Credentials

**Username:** `admin`
**Password:** `changeme`

**⚠️ IMPORTANT:** Change this password immediately after first login!

---

## 🧪 Test After Migration

Try accessing these URLs (they should redirect to Authelia login):

1. **Homepage:** https://home.yourdomain.com
2. **Home Assistant:** https://ha.yourdomain.com
3. **Jellyseerr:** https://request.yourdomain.com
4. **Authelia Portal:** https://auth.yourdomain.com

---

## 🔧 What The Script Does

### Before Migration:
- Authentik running on port 9000
- 4 containers (Server, Worker, PostgreSQL, Redis)
- ~400-500MB RAM usage

### After Migration:
- Authelia running on port 9091
- 2 containers (Authelia, Redis)
- ~100-150MB RAM usage
- Faster startup time

---

## 📊 Current Status

- ✅ Authentik is running
- ✅ Caddy is running
- ✅ All configuration files ready
- ✅ Secrets generated
- ✅ Admin user configured
- ✅ Migration script ready

---

## 🆘 If Something Goes Wrong

### View Logs
```bash
docker logs authelia -f
docker logs caddy -f
```

### Rollback to Authentik
```bash
cd /opt/docker/homelab/services/authelia
docker compose down

cd /opt/docker/homelab/services/authentik
docker compose up -d

cd /opt/docker/homelab/services/public  
docker compose up -d
```

### Get Help
- Check `README.md` for troubleshooting
- See `MIGRATION-AUTHENTIK-TO-AUTHELIA.md` for detailed steps

---

## ✨ After Successful Migration

1. **Change default password**
   - Login as admin/changeme
   - Go to settings and change password

2. **Set up 2FA**
   - Click "Register device"
   - Scan QR code with authenticator app

3. **Add more users** (if needed)
   ```bash
   # Generate password hash
   docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password 'newpassword'
   
   # Edit users file
   nano /home/coenw/Dev/homelab-docker/services/authelia/staticconfig/users_database.yml
   
   # Restart Authelia
   docker restart authelia
   ```

4. **Clean up Authentik** (after confirming everything works)
   ```bash
   rm -rf /opt/docker/homelab/services/authentik
   docker network rm authentik-net
   ```

---

## 📞 Support Files

- `complete-migration.sh` - Run this to migrate
- `START-HERE.md` - Quick start guide
- `README.md` - Complete documentation
- `MIGRATION-AUTHENTIK-TO-AUTHELIA.md` - Detailed migration guide
- `GENERATED-SECRETS.env` - Your secrets
- `CHANGES-SUMMARY.md` - What changed

---

## Ready?

```bash
cd /home/coenw/Dev/homelab-docker/services/authelia
./complete-migration.sh
```

**Good luck! 🚀**





