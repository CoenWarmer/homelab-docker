#!/bin/bash

####################
# Quick Migration Script: Authentik → Authelia
####################
# This script helps automate the migration process

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOMELAB_DIR="/opt/docker/homelab"

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Authentik → Authelia Migration Assistant    ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}\n"

# Check if running with proper permissions
if [ ! -w "$HOMELAB_DIR" ]; then
    echo -e "${RED}Error: Cannot write to $HOMELAB_DIR${NC}"
    echo "Please ensure you have proper permissions or update HOMELAB_DIR in this script"
    exit 1
fi

# Step 1: Generate Secrets
echo -e "${YELLOW}Step 1: Generate Secrets${NC}"
echo "Generating secure secrets..."
JWT_SECRET=$(openssl rand -base64 64 | tr -d '\n')
SESSION_SECRET=$(openssl rand -base64 64 | tr -d '\n')
ENCRYPTION_KEY=$(openssl rand -base64 64 | tr -d '\n')

echo -e "${GREEN}✓ Secrets generated${NC}\n"

# Step 2: Display secrets
echo -e "${YELLOW}Step 2: Secrets to Add to .env${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "Add these lines to: ${HOMELAB_DIR}/.env"
echo ""
echo "# Authelia Configuration"
echo "PORT_AUTHELIA=9091"
echo "AUTHELIA_JWT_SECRET=${JWT_SECRET}"
echo "AUTHELIA_SESSION_SECRET=${SESSION_SECRET}"
echo "AUTHELIA_ENCRYPTION_KEY=${ENCRYPTION_KEY}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

read -p "Press Enter when you've added these to .env..."

# Step 3: Backup Authentik
echo -e "\n${YELLOW}Step 3: Backup Authentik (Optional)${NC}"
read -p "Do you want to backup Authentik data? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    BACKUP_DIR="$HOME/authelia-migration-backup-$(date +%Y%m%d)"
    mkdir -p "$BACKUP_DIR"
    
    if docker ps | grep -q authentik_db; then
        echo "Backing up Authentik database..."
        docker exec authentik_db pg_dump -U authentik authentik > "$BACKUP_DIR/authentik_backup.sql"
        echo -e "${GREEN}✓ Database backed up${NC}"
    fi
    
    if docker ps | grep -q authentik_redis; then
        echo "Backing up Redis..."
        docker exec authentik_redis redis-cli SAVE
        sudo cp /mnt/storage/db/authentik-redis/dump.rdb "$BACKUP_DIR/authentik_redis_backup.rdb" 2>/dev/null || true
        echo -e "${GREEN}✓ Redis backed up${NC}"
    fi
    
    echo -e "${GREEN}✓ Backups saved to: $BACKUP_DIR${NC}\n"
fi

# Step 4: Create directories
echo -e "${YELLOW}Step 4: Create Directories${NC}"
sudo mkdir -p /srv/docker/authelia
sudo mkdir -p /mnt/storage/db/authelia-redis
sudo chown -R $USER:docker /srv/docker/authelia 2>/dev/null || sudo chown -R $USER:$USER /srv/docker/authelia
sudo chown -R $USER:docker /mnt/storage/db/authelia-redis 2>/dev/null || sudo chown -R $USER:$USER /mnt/storage/db/authelia-redis
echo -e "${GREEN}✓ Directories created${NC}\n"

# Step 5: Create network
echo -e "${YELLOW}Step 5: Create Docker Network${NC}"
if docker network ls | grep -q authelia-net; then
    echo "Network authelia-net already exists"
else
    docker network create authelia-net
    echo -e "${GREEN}✓ Network created${NC}"
fi
echo ""

# Step 6: User configuration
echo -e "${YELLOW}Step 6: Configure Users${NC}"
echo "You need to configure users in: services/authelia/staticconfig/users_database.yml"
echo ""
echo "Generate a password hash with:"
echo "  docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password 'your-password'"
echo ""
read -p "Press Enter when you've configured at least one user..."

# Step 7: Create symlink
echo -e "\n${YELLOW}Step 7: Create .env Symlink${NC}"
cd "$SCRIPT_DIR"
ln -sf ../../.env .env 2>/dev/null || ln -sf "$HOMELAB_DIR/.env" .env
echo -e "${GREEN}✓ Symlink created${NC}\n"

# Step 8: Stop services
echo -e "${YELLOW}Step 8: Stop Current Services${NC}"
read -p "Ready to stop Authentik and Caddy? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$HOMELAB_DIR/services/public"
    docker compose down
    
    cd "$HOMELAB_DIR/services/authentik"
    docker compose down
    
    echo -e "${GREEN}✓ Services stopped${NC}\n"
fi

# Step 9: Start Authelia
echo -e "${YELLOW}Step 9: Start Authelia${NC}"
read -p "Ready to start Authelia? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$SCRIPT_DIR"
    docker compose up -d
    
    echo "Waiting for Authelia to start..."
    sleep 10
    
    if docker ps | grep -q authelia; then
        echo -e "${GREEN}✓ Authelia started${NC}"
        echo "Checking logs..."
        docker logs authelia --tail 20
    else
        echo -e "${RED}✗ Authelia failed to start${NC}"
        echo "Check logs with: docker logs authelia"
        exit 1
    fi
fi
echo ""

# Step 10: Start Caddy
echo -e "${YELLOW}Step 10: Start Caddy${NC}"
read -p "Ready to start Caddy? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$HOMELAB_DIR/services/public"
    docker compose up -d
    
    echo "Waiting for Caddy to start..."
    sleep 5
    
    if docker ps | grep -q caddy; then
        echo -e "${GREEN}✓ Caddy started${NC}\n"
    else
        echo -e "${RED}✗ Caddy failed to start${NC}"
        echo "Check logs with: docker logs caddy"
        exit 1
    fi
fi

# Final summary
echo -e "\n${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            Migration Complete! 🎉              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}Next Steps:${NC}"
echo "1. Test login at: https://auth.yourdomain.com"
echo "2. Test protected services:"
echo "   - https://home.yourdomain.com"
echo "   - https://ha.yourdomain.com"
echo "   - https://request.yourdomain.com"
echo "3. Set up 2FA for all users"
echo "4. After confirming everything works:"
echo "   - Remove /opt/docker/homelab/services/authentik"
echo "   - Remove network: docker network rm authentik-net"
echo ""
echo -e "${YELLOW}Troubleshooting:${NC}"
echo "  - Logs: docker logs authelia -f"
echo "  - Status: docker ps"
echo "  - Verify: curl -I http://localhost:9091"
echo ""
echo "See MIGRATION-AUTHENTIK-TO-AUTHELIA.md for full documentation"
echo ""





