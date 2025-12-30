# Authelia - SSO & Identity Provider

Single Sign-On (SSO) and Identity Provider for securing your homelab services with forward authentication.

## Services

- **Authelia** - Main authentication server
- **Redis** - Session storage

## Why Authelia?

Authelia is a lightweight authentication and authorization server that:
- ✅ Provides forward authentication for reverse proxies
- ✅ Supports two-factor authentication (TOTP, WebAuthn)
- ✅ Lower resource usage than Authentik
- ✅ Simple YAML-based configuration
- ✅ File-based user management (no database required for users)

## Initial Setup

### 1. Add Environment Variables

Add these to your `/opt/docker/homelab/.env`:

```bash
# Authelia
PORT_AUTHELIA=9091

# Secrets (generate with commands below)
AUTHELIA_JWT_SECRET=<generate>
AUTHELIA_SESSION_SECRET=<generate>
AUTHELIA_ENCRYPTION_KEY=<generate>
```

**Generate secure secrets:**
```bash
# JWT Secret (64 bytes)
openssl rand -base64 64

# Session Secret (64 bytes)
openssl rand -base64 64

# Encryption Key (64 bytes)
openssl rand -base64 64
```

### 2. Create Required Directories

```bash
sudo mkdir -p /srv/docker/authelia
sudo mkdir -p /mnt/storage/db/authelia-redis
sudo chown -R $USER:docker /srv/docker/authelia
sudo chown -R $USER:docker /mnt/storage/db/authelia-redis
```

### 3. Configure Users

Edit `staticconfig/users_database.yml` and add your users.

**Generate a password hash:**
```bash
docker run authelia/authelia:latest authelia crypto hash generate argon2 --password 'your-password-here'
```

Copy the hash and add it to the users file:
```yaml
users:
  yourusername:
    displayname: "Your Name"
    password: "$argon2id$v=19$m=65536,t=3,p=4$..." # paste hash here
    email: your@email.com
    groups:
      - admins
      - users
```

### 4. Create Network

```bash
docker network create authelia-net
```

### 5. Start Authelia

```bash
cd /opt/docker/homelab/services/authelia
docker compose up -d

# Watch the logs
docker logs authelia -f
```

### 6. Access Authelia

Navigate to `http://your-server-ip:9091` or `https://auth.yourdomain.com`

## Integration with Caddy (Forward Auth)

Authelia is integrated with Caddy using forward authentication. The Caddyfile snippet `(authelia)` is automatically applied to protected services.

### Protected Services

The following services are protected by Authelia:
- `{$DOMAIN}` - Main domain
- `home.{$DOMAIN}` - Homepage Dashboard
- `ha.{$DOMAIN}` - Home Assistant
- `request.{$DOMAIN}` - Jellyseerr

### Caddy Configuration

The `(authelia)` snippet in the Caddyfile:

```caddyfile
(authelia) {
  forward_auth authelia:9091 {
    uri /api/verify?rd=https://auth.{$DOMAIN}
    copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
    trusted_proxies private_ranges
  }
}
```

## Two-Factor Authentication (2FA)

### Setup TOTP (Recommended)

1. Log in to any protected service
2. You'll be redirected to Authelia
3. Click "Register device" under Two-Factor Authentication
4. Scan the QR code with your authenticator app (Google Authenticator, Authy, etc.)
5. Enter the code to confirm

### Setup WebAuthn (Security Keys)

1. Log in to Authelia
2. Go to Settings → Two-Factor Authentication
3. Click "Register Security Key"
4. Follow the prompts to register your hardware key (YubiKey, etc.)

## Adding New Users

1. Generate a password hash:
```bash
docker run authelia/authelia:latest authelia crypto hash generate argon2 --password 'newuserpassword'
```

2. Edit `staticconfig/users_database.yml`:
```yaml
users:
  newuser:
    displayname: "New User"
    password: "$argon2id$v=19$m=65536,t=3,p=4$..."
    email: newuser@example.com
    groups:
      - users
```

3. Restart Authelia:
```bash
docker restart authelia
```

## Protecting New Services

To protect a new service with Authelia:

1. Ensure the service is on the `caddy-net` network
2. Add a domain entry in the Caddyfile:
```caddyfile
newservice.{$DOMAIN} {
  import headers
  import main
  import authelia  # This line enables authentication
  
  reverse_proxy newservice:port
}
```

3. Update Authelia's access control in `staticconfig/configuration.yml`:
```yaml
access_control:
  rules:
    - domain:
        - "newservice.${DOMAIN}"
      policy: two_factor  # or 'one_factor' for password only
```

4. Restart both Caddy and Authelia:
```bash
docker restart caddy authelia
```

## Access Control Policies

- **bypass** - No authentication required
- **one_factor** - Username + password only
- **two_factor** - Username + password + 2FA (recommended)

## Troubleshooting

### Check Logs
```bash
docker logs authelia
```

### Test Forward Auth
```bash
curl -v http://localhost:9091/api/verify
```

### Reset User Password
1. Generate new hash with the command above
2. Update `users_database.yml`
3. Restart Authelia

### Common Issues

**Issue**: Can't log in / "Access Denied"
- Check that user exists in `users_database.yml`
- Verify password hash is correct
- Check access control rules in `configuration.yml`

**Issue**: Redirect loop
- Verify `session.domain` matches your domain
- Check that the Caddy snippet is correctly configured
- Ensure `trusted_proxies` includes your network

**Issue**: 2FA not working
- Ensure time is synced on server (NTP)
- Check that TOTP secret was properly saved

## OIDC Configuration (Optional)

For services that support OIDC/OAuth2 (like Jellyfin):

1. Generate client secret:
```bash
docker run authelia/authelia:latest authelia crypto hash generate pbkdf2 --random --random.length=72
```

2. Add client to `configuration.yml`:
```yaml
identity_providers:
  oidc:
    clients:
      - id: jellyfin
        description: Jellyfin Media Server
        secret: '$pbkdf2-sha512$...'
        public: false
        authorization_policy: two_factor
        redirect_uris:
          - https://jelly.${DOMAIN}/sso/OID/redirect/authelia
        scopes:
          - openid
          - profile
          - groups
          - email
```

3. Restart Authelia and configure the service to use Authelia as OIDC provider

## Maintenance

### Backup
```bash
# Backup Authelia configuration and database
tar -czf authelia-backup-$(date +%Y%m%d).tar.gz /srv/docker/authelia

# Backup Redis data
docker exec authelia_redis redis-cli SAVE
cp /mnt/storage/db/authelia-redis/dump.rdb ./authelia-redis-backup.rdb
```

### Update Authelia
```bash
cd /opt/docker/homelab/services/authelia
docker compose pull
docker compose up -d
```

## Resources

- [Authelia Documentation](https://www.authelia.com/overview/prologue/introduction/)
- [Forward Auth with Caddy](https://www.authelia.com/integration/proxies/caddy/)
- [Access Control](https://www.authelia.com/configuration/security/access-control/)





