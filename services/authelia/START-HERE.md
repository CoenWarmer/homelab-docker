# 🚀 START HERE - Authentik to Authelia Migration

## ✅ What's Done

All the refactoring work is **COMPLETE**! Here's what was created and updated:

### 📦 New Authelia Service
- ✅ Docker Compose configuration with Authelia + Redis
- ✅ Authelia configuration file with access control rules
- ✅ User database template
- ✅ Comprehensive README with setup instructions
- ✅ Automated migration script
- ✅ Environment variable templates

### 🔧 Updated Files
- ✅ Caddyfile - Authelia forward auth integration
- ✅ start-public-stack.sh - Uses Authelia instead of Authentik
- ✅ stop-public-stack.sh - Uses Authelia instead of Authentik  
- ✅ start-all.sh - Updated references and ports

### 📚 Documentation
- ✅ Complete migration guide
- ✅ Changes summary
- ✅ Troubleshooting guide

## 🎯 Quick Start - Three Ways to Migrate

### Option 1: Automated Script (Recommended)
```bash
cd /home/coenw/Dev/homelab-docker/services/authelia
./quick-migrate.sh
```
This interactive script will guide you through each step!

### Option 2: Manual Migration
Follow the complete guide:
```bash
cd /home/coenw/Dev/homelab-docker
cat MIGRATION-AUTHENTIK-TO-AUTHELIA.md
```

### Option 3: Quick Manual Steps
```bash
# 1. Generate secrets and add to .env
openssl rand -base64 64  # JWT Secret
openssl rand -base64 64  # Session Secret
openssl rand -base64 64  # Encryption Key

# 2. Edit .env (add the secrets generated above)
nano /opt/docker/homelab/.env

# 3. Configure at least one user
cd services/authelia
nano staticconfig/users_database.yml

# 4. Create directories & network
sudo mkdir -p /srv/docker/authelia /mnt/storage/db/authelia-redis
sudo chown -R $USER:docker /srv/docker/authelia /mnt/storage/db/authelia-redis
docker network create authelia-net

# 5. Stop current services
cd /opt/docker/homelab/services/public && docker compose down
cd /opt/docker/homelab/services/authentik && docker compose down

# 6. Start Authelia
cd /opt/docker/homelab/services/authelia
ln -sf ../../.env .env
docker compose up -d

# 7. Start Caddy
cd /opt/docker/homelab/services/public
docker compose up -d

# 8. Test login at https://auth.yourdomain.com
```

## 📋 Pre-Migration Checklist

Before you start, make sure you have:
- [ ] Access to `/opt/docker/homelab/.env` to add secrets
- [ ] Sudo permissions for directory creation
- [ ] List of users to migrate from Authentik
- [ ] Time for brief downtime (~5-10 minutes)

## 🔐 Required Environment Variables

Add these to `/opt/docker/homelab/.env`:

```bash
# Authelia Port
PORT_AUTHELIA=9091

# Authelia Secrets (generate with openssl rand -base64 64)
AUTHELIA_JWT_SECRET=your_generated_secret_here
AUTHELIA_SESSION_SECRET=your_generated_secret_here
AUTHELIA_ENCRYPTION_KEY=your_generated_secret_here
```

See `SECRETS-TEMPLATE.env` for the template.

## 👥 User Configuration

Edit `staticconfig/users_database.yml` and add your users:

**Generate password hash:**
```bash
docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password 'yourpassword'
```

**Add to users_database.yml:**
```yaml
users:
  yourusername:
    displayname: "Your Name"
    password: "$argon2id$v=19$m=65536,t=3,p=4$..."
    email: your@email.com
    groups:
      - admins
      - users
```

## 📖 Documentation Files

| File | Purpose |
|------|---------|
| `START-HERE.md` | This file - quick overview |
| `README.md` | Complete Authelia service documentation |
| `MIGRATION-AUTHENTIK-TO-AUTHELIA.md` | Step-by-step migration guide |
| `CHANGES-SUMMARY.md` | List of all changes made |
| `SECRETS-TEMPLATE.env` | Environment variable template |
| `quick-migrate.sh` | Automated migration script |

## 🎨 What Changed?

### Architecture
**Before**: Authentik (4 containers, 400-500MB RAM)
- authentik_server
- authentik_worker  
- authentik_db (PostgreSQL)
- authentik_redis

**After**: Authelia (2 containers, 100-150MB RAM)
- authelia
- authelia_redis

### Port Changes
- Authentik: `http://localhost:9000`
- Authelia: `http://localhost:9091`

### Configuration
- Authentik: Web UI + YAML
- Authelia: YAML only (simpler!)

### Forward Auth
- Authentik: `/outpost.goauthentik.io/auth/caddy`
- Authelia: `/api/verify`

## ✨ Benefits of Authelia

1. **Lighter** - 60-70% less memory usage
2. **Faster** - Starts in ~5 seconds vs ~15 seconds
3. **Simpler** - Single YAML config, no complex UI
4. **Efficient** - Built specifically for forward auth
5. **Secure** - Industry-standard Argon2id password hashing

## 🧪 Testing After Migration

Test these protected services:
1. https://home.yourdomain.com (Homepage Dashboard)
2. https://ha.yourdomain.com (Home Assistant)
3. https://request.yourdomain.com (Jellyseerr)
4. https://yourdomain.com (Main domain)

Each should:
- Redirect to https://auth.yourdomain.com
- Allow login with configured credentials
- Redirect back to the service after login
- Offer 2FA setup option

## 🆘 Need Help?

### Check Logs
```bash
docker logs authelia -f
docker logs caddy -f
```

### Common Issues

**Issue: Can't log in**
- Check password hash in `users_database.yml`
- Verify user exists
- Check logs for authentication errors

**Issue: Redirect loop**
- Verify `.env` has correct secrets
- Check session domain matches your domain
- Ensure time is synced (important for JWT)

**Issue: Services not protected**
- Check Caddyfile has `import authelia`
- Restart Caddy: `docker restart caddy`
- Check access control rules in `configuration.yml`

### Get More Details
- `README.md` - Service documentation
- `MIGRATION-AUTHENTIK-TO-AUTHELIA.md` - Full migration guide
- [Authelia Docs](https://www.authelia.com/) - Official documentation

## 🎯 Next Steps

1. **Choose your migration method** (automated or manual)
2. **Generate and add secrets** to .env
3. **Configure users** in users_database.yml
4. **Run the migration** (5-10 minutes downtime)
5. **Test login** on protected services
6. **Set up 2FA** for all users
7. **Clean up Authentik** after confirming everything works

## 🎉 Ready to Begin?

```bash
cd /home/coenw/Dev/homelab-docker/services/authelia
./quick-migrate.sh
```

Good luck! 🚀

---

**Need to Rollback?**
See `MIGRATION-AUTHENTIK-TO-AUTHELIA.md` for the rollback procedure.

**Questions?**
All configuration is documented in `README.md` and the migration guide.





