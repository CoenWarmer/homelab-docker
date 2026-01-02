#!/bin/bash
#############################################
# Homelab Secret Rotation Script
# 
# RUN THIS OUTSIDE OF THE AI CONVERSATION!
# Run from: services/authelia/
#############################################

set -e

SECRETS_DIR="/tmp/homelab-secrets-$$"
ENV_FILE="/opt/docker/homelab/.env"
CONFIG_FILE="./staticconfig/configuration.yml"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source .env to get CONFIGDIR
source "$ENV_FILE"

echo "=== Homelab Secret Rotation ==="
echo ""
echo "This script will rotate secrets for:"
echo ""
echo "  AUTHELIA:"
echo "    - Storage encryption key (re-encrypts database)"
echo "    - JWT, Session, OIDC secrets"
echo "    - RSA private key"
echo "    - OIDC client secrets (Jellyfin/Jellyseerr)"
echo ""
echo "  OTHER SERVICES:"
echo "    - Gluetun API key"
echo "    - Paperless secret key"
echo "    - Pi-hole password"
echo "    - Radarr, Sonarr, Lidarr, Prowlarr API keys"
echo "    - SABnzbd API key"
echo ""
echo "⚠️  REQUIREMENTS:"
echo "  - Authelia container must be running (for encryption key rotation)"
echo "  - Arr apps and SABnzbd will be stopped/started during rotation"
echo ""
echo "⚠️  WARNING: This will NOT rotate:"
echo "  - SMTP password (managed by Proton Bridge)"
echo "  - VPN credentials (managed by provider)"
echo "  - DuckDNS token (managed on duckdns.org)"
echo "  - Database passwords (requires migration)"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Check if Authelia is running
if ! docker ps --format '{{.Names}}' | grep -q '^authelia$'; then
    echo ""
    echo "❌ ERROR: Authelia container is not running!"
    echo "   Storage encryption key rotation requires a running Authelia instance."
    echo "   Please start Authelia first: docker compose up -d"
    exit 1
fi

# Create secure temp directory
mkdir -p "$SECRETS_DIR"
chmod 700 "$SECRETS_DIR"

echo ""
echo "=== Rotating Storage Encryption Key ==="
echo "This re-encrypts the database with a new key (preserves all data)..."

# Generate new encryption key
NEW_ENCRYPTION_KEY=$(openssl rand -base64 64 | tr -d '\n')

# Run the change-key command on the running container
if docker exec authelia authelia storage encryption change-key --new-encryption-key "$NEW_ENCRYPTION_KEY"; then
    echo "✅ Storage encryption key rotated successfully"
else
    echo "❌ Failed to rotate storage encryption key"
    echo "   The database may still be using the old key."
    read -p "Continue with other secrets anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        rm -rf "$SECRETS_DIR"
        exit 1
    fi
    NEW_ENCRYPTION_KEY=""  # Don't update .env if rotation failed
fi

echo ""
echo "=== Generating new secrets ==="

# Generate plain secrets
JELLYFIN_PLAIN=$(openssl rand -hex 32)
JELLYSEERR_PLAIN=$(openssl rand -hex 32)
JWT_SECRET=$(openssl rand -base64 64 | tr -d '\n')
SESSION_SECRET=$(openssl rand -base64 64 | tr -d '\n')
OIDC_HMAC=$(openssl rand -hex 32)

# Generate RSA key (saved directly to staticconfig, not .env)
openssl genrsa 4096 2>/dev/null > "$SCRIPT_DIR/staticconfig/oidc_issuer_key.pem"
chmod 600 "$SCRIPT_DIR/staticconfig/oidc_issuer_key.pem"
echo "✅ New RSA key saved to staticconfig/oidc_issuer_key.pem"

# Hash OIDC secrets
echo "Hashing OIDC client secrets (this may take a moment)..."
JELLYFIN_HASH=$(docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password "$JELLYFIN_PLAIN" 2>/dev/null | grep 'Digest:' | awk '{print $2}')
JELLYSEERR_HASH=$(docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password "$JELLYSEERR_PLAIN" 2>/dev/null | grep 'Digest:' | awk '{print $2}')

echo ""
echo "=== Updating .env file ==="

# Backup .env
cp "$ENV_FILE" "$ENV_FILE.backup.$(date +%Y%m%d%H%M%S)"

# Update .env file using sed
sed -i "s|^AUTHELIA_JWT_SECRET=.*|AUTHELIA_JWT_SECRET=$JWT_SECRET|" "$ENV_FILE"
sed -i "s|^AUTHELIA_SESSION_SECRET=.*|AUTHELIA_SESSION_SECRET=$SESSION_SECRET|" "$ENV_FILE"
sed -i "s|^AUTHELIA_OIDC_HMAC_SECRET=.*|AUTHELIA_OIDC_HMAC_SECRET=$OIDC_HMAC|" "$ENV_FILE"

# Update storage encryption key (only if rotation succeeded)
if [[ -n "$NEW_ENCRYPTION_KEY" ]]; then
    sed -i "s|^AUTHELIA_ENCRYPTION_KEY=.*|AUTHELIA_ENCRYPTION_KEY=$NEW_ENCRYPTION_KEY|" "$ENV_FILE"
    # Also try the alternate variable name
    sed -i "s|^AUTHELIA_STORAGE_ENCRYPTION_KEY=.*|AUTHELIA_STORAGE_ENCRYPTION_KEY=$NEW_ENCRYPTION_KEY|" "$ENV_FILE"
    echo "✅ Storage encryption key updated in .env"
fi

# RSA key is now stored in staticconfig/oidc_issuer_key.pem (not in .env)
# Remove old RSA key from .env if it exists (cleanup)
sed -i '/^AUTHELIA_OIDC_ISSUER_PRIVATE_KEY=/,/^-----END PRIVATE KEY-----$/d' "$ENV_FILE" 2>/dev/null || true

echo ""
echo "=== Updating configuration.yml ==="

# Update hashed secrets in configuration.yml
sed -i "s|client_secret: '.*'  # Jellyfin|client_secret: '$JELLYFIN_HASH'  # Jellyfin|" "$CONFIG_FILE" 2>/dev/null || true

# More robust replacement using the client_id as anchor
# For Jellyfin
sed -i "/client_id: 'jellyfin'/,/client_id:/{s|client_secret: '.*'|client_secret: '$JELLYFIN_HASH'|}" "$CONFIG_FILE"
# For Jellyseerr  
sed -i "/client_id: 'jellyseerr'/,/client_id:/{s|client_secret: '.*'|client_secret: '$JELLYSEERR_HASH'|}" "$CONFIG_FILE"

echo ""
echo "=== Rotating Gluetun API Key ==="
NEW_GLUETUN_API=$(openssl rand -hex 16)
sed -i "s|^GLUETUN_APIKEY=.*|GLUETUN_APIKEY=$NEW_GLUETUN_API|" "$ENV_FILE"
echo "✅ Gluetun API key rotated"

echo ""
echo "=== Rotating Paperless Secret Key ==="
NEW_PAPERLESS_SECRET=$(openssl rand -base64 32 | tr -d '\n')
sed -i "s|^PAPERLESS_SECRETKEY=.*|PAPERLESS_SECRETKEY=$NEW_PAPERLESS_SECRET|" "$ENV_FILE"
echo "✅ Paperless secret key rotated (users will need to re-login)"

echo ""
echo "=== Rotating Pi-hole Password ==="
NEW_PIHOLE_PASS=$(openssl rand -base64 16 | tr -d '\n')
if docker ps --format '{{.Names}}' | grep -q '^pihole$'; then
    if docker exec pihole pihole -a -p "$NEW_PIHOLE_PASS" > /dev/null 2>&1; then
        sed -i "s|^PIHOLE_PASSWORD=.*|PIHOLE_PASSWORD=$NEW_PIHOLE_PASS|" "$ENV_FILE"
        echo "✅ Pi-hole password rotated"
    else
        echo "⚠️  Failed to rotate Pi-hole password (container command failed)"
    fi
else
    echo "⚠️  Pi-hole container not running, skipping password rotation"
fi

echo ""
echo "=== Rotating Arr Apps API Keys ==="
echo "This requires stopping containers to modify config files..."

# Function to rotate arr app API key
rotate_arr_api() {
    local APP_NAME="$1"
    local CONTAINER_NAME="$2"
    local CONFIG_PATH="$3"
    local ENV_VAR="$4"
    
    if [[ ! -f "$CONFIG_PATH" ]]; then
        echo "⚠️  $APP_NAME config not found at $CONFIG_PATH, skipping"
        return
    fi
    
    # Generate new API key (32 hex chars like the arr apps use)
    local NEW_API_KEY=$(openssl rand -hex 16)
    
    # Stop container if running
    local WAS_RUNNING=false
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        WAS_RUNNING=true
        docker stop "$CONTAINER_NAME" > /dev/null 2>&1 || true
        sleep 2
    fi
    
    # Update config.xml
    sed -i "s|<ApiKey>.*</ApiKey>|<ApiKey>$NEW_API_KEY</ApiKey>|" "$CONFIG_PATH"
    
    # Update .env
    sed -i "s|^${ENV_VAR}=.*|${ENV_VAR}=$NEW_API_KEY|" "$ENV_FILE"
    
    # Restart container if it was running
    if $WAS_RUNNING; then
        docker start "$CONTAINER_NAME" > /dev/null 2>&1 || true
    fi
    
    echo "✅ $APP_NAME API key rotated"
}

# Rotate each arr app
rotate_arr_api "Radarr" "radarr" "${CONFIGDIR}/radarr3/config.xml" "HOMEPAGE_RADARR_API"
rotate_arr_api "Sonarr" "sonarr" "${CONFIGDIR}/sonarr/config.xml" "HOMEPAGE_SONARR_API"
rotate_arr_api "Lidarr" "lidarr" "${CONFIGDIR}/lidarr/config.xml" "HOMEPAGE_LIDARR_API"
rotate_arr_api "Prowlarr" "prowlarr" "${CONFIGDIR}/prowlarr/config.xml" "HOMEPAGE_PROWLARR_API"

echo ""
echo "=== Rotating SABnzbd API Key ==="
SABNZBD_INI="${CONFIGDIR}/sabnzbd/sabnzbd.ini"
if [[ -f "$SABNZBD_INI" ]]; then
    NEW_SABNZBD_API=$(openssl rand -hex 16)
    
    # Stop container if running
    SABNZBD_WAS_RUNNING=false
    if docker ps --format '{{.Names}}' | grep -q '^sabnzbd$'; then
        SABNZBD_WAS_RUNNING=true
        docker stop sabnzbd > /dev/null 2>&1 || true
        sleep 2
    fi
    
    # Update sabnzbd.ini
    sed -i "s|^api_key = .*|api_key = $NEW_SABNZBD_API|" "$SABNZBD_INI"
    
    # Update .env
    sed -i "s|^HOMEPAGE_SABNZBD_API=.*|HOMEPAGE_SABNZBD_API=$NEW_SABNZBD_API|" "$ENV_FILE"
    
    # Restart container if it was running
    if $SABNZBD_WAS_RUNNING; then
        docker start sabnzbd > /dev/null 2>&1 || true
    fi
    
    echo "✅ SABnzbd API key rotated"
else
    echo "⚠️  SABnzbd config not found at $SABNZBD_INI, skipping"
fi

echo ""
echo "=== Saving plain secrets for app configuration ==="

# Save plain secrets for user to configure apps
cat > "$SECRETS_DIR/PLAIN_SECRETS_FOR_APPS.txt" << EOF
=====================================================
KEEP THIS FILE SECURE - DELETE AFTER CONFIGURING APPS
=====================================================

These are the PLAIN secrets needed to configure your apps.
Use them in Jellyfin SSO Plugin and Jellyseerr OIDC settings.

JELLYFIN OIDC CLIENT SECRET:
$JELLYFIN_PLAIN

JELLYSEERR OIDC CLIENT SECRET:
$JELLYSEERR_PLAIN

=====================================================
After configuring both apps, delete this file:
  rm -rf $SECRETS_DIR
=====================================================
EOF

chmod 600 "$SECRETS_DIR/PLAIN_SECRETS_FOR_APPS.txt"

echo ""
echo "=== Done! ==="
echo ""
echo "✅ Secrets rotated successfully!"
echo ""
echo "Rotated:"
echo "  ✅ Authelia: JWT, Session, OIDC HMAC, RSA key, client secrets"
if [[ -n "$NEW_ENCRYPTION_KEY" ]]; then
    echo "  ✅ Authelia: Storage encryption key (database re-encrypted)"
fi
echo "  ✅ Gluetun API key"
echo "  ✅ Paperless secret key"
echo "  ✅ Pi-hole password (if container was running)"
echo "  ✅ Radarr, Sonarr, Lidarr, Prowlarr API keys"
echo "  ✅ SABnzbd API key"
echo ""
echo "📋 NEXT STEPS:"
echo ""
echo "1. Restart affected services:"
echo "   cd /home/coenw/Dev/homelab-docker"
echo "   docker compose -f services/authelia/docker-compose.yml up -d --force-recreate"
echo "   docker compose -f services/downloads/docker-compose.yml up -d --force-recreate"
echo "   docker compose -f services/paperless/docker-compose.yml up -d --force-recreate"
echo ""
echo "2. Update Jellyfin SSO plugin with new client secret"
echo "3. Update Jellyseerr OIDC settings with new client secret"
echo ""
echo "4. View the plain secrets for app configuration:"
echo "   cat $SECRETS_DIR/PLAIN_SECRETS_FOR_APPS.txt"
echo ""
echo "5. After configuring apps, DELETE the plain secrets:"
echo "   rm -rf $SECRETS_DIR"
echo ""
echo "📁 Backup of old .env saved to: $ENV_FILE.backup.*"
echo ""
echo "⚠️  STILL NEED MANUAL ROTATION:"
echo "  - SMTP password (Proton Bridge)"
echo "  - VPN credentials (your provider)"
echo "  - DuckDNS token (duckdns.org)"
echo "  - Home Assistant API key (HA UI)"
echo "  - Jellyfin API key (Jellyfin UI)"
echo "  - qBittorrent credentials (qBittorrent UI)"

