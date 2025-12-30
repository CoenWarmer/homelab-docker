#!/bin/bash

####################
# Complete Authelia Migration Script
####################
# Run this in your terminal to complete the migration

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Authentik → Authelia Migration              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"

# Step 1: Add secrets to .env
echo -e "${YELLOW}Step 1: Adding secrets to .env${NC}"
if grep -q "AUTHELIA_JWT_SECRET" /opt/docker/homelab/.env 2>/dev/null; then
    echo "Secrets already in .env, skipping..."
else
    echo "Adding secrets..."
    sudo tee -a /opt/docker/homelab/.env < /home/coenw/Dev/homelab-docker/services/authelia/GENERATED-SECRETS.env > /dev/null
    echo -e "${GREEN}✅ Secrets added${NC}"
fi
echo ""

# Step 2: Create directories
echo -e "${YELLOW}Step 2: Creating directories${NC}"
sudo mkdir -p /srv/docker/authelia
sudo mkdir -p /mnt/storage/db/authelia-redis
sudo chown -R $USER:$USER /srv/docker/authelia
sudo chown -R $USER:$USER /mnt/storage/db/authelia-redis
echo -e "${GREEN}✅ Directories created${NC}\n"

# Step 3: Create network
echo -e "${YELLOW}Step 3: Creating Docker network${NC}"
if docker network ls | grep -q authelia-net; then
    echo "Network authelia-net already exists"
else
    docker network create authelia-net
    echo -e "${GREEN}✅ Network created${NC}"
fi
echo ""

# Step 4: Create symlink
echo -e "${YELLOW}Step 4: Creating .env symlink${NC}"
cd /home/coenw/Dev/homelab-docker/services/authelia
ln -sf /opt/docker/homelab/.env .env
echo -e "${GREEN}✅ Symlink created${NC}\n"

# Step 5: Stop current services
echo -e "${YELLOW}Step 5: Stopping Authentik and Caddy${NC}"
cd /opt/docker/homelab/services/public
docker compose down
echo "Public services stopped"

cd /opt/docker/homelab/services/authentik
docker compose down
echo "Authentik stopped"
echo -e "${GREEN}✅ Services stopped${NC}\n"

# Step 6: Start Authelia
echo -e "${YELLOW}Step 6: Starting Authelia${NC}"
cd /home/coenw/Dev/homelab-docker/services/authelia
docker compose up -d

echo "Waiting for Authelia to start..."
sleep 8

if docker ps | grep -q authelia; then
    echo -e "${GREEN}✅ Authelia started successfully${NC}"
    echo ""
    echo "Authelia logs (last 15 lines):"
    docker logs authelia --tail 15
else
    echo -e "${RED}❌ Authelia failed to start${NC}"
    docker logs authelia
    exit 1
fi
echo ""

# Step 7: Start Caddy
echo -e "${YELLOW}Step 7: Starting Caddy${NC}"
cd /opt/docker/homelab/services/public
docker compose up -d

echo "Waiting for Caddy to start..."
sleep 5

if docker ps | grep -q caddy; then
    echo -e "${GREEN}✅ Caddy started successfully${NC}"
else
    echo -e "${RED}❌ Caddy failed to start${NC}"
    docker logs caddy
    exit 1
fi
echo ""

# Step 8: Verify
echo -e "${YELLOW}Step 8: Verifying services${NC}"
echo ""
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "authelia|caddy"
echo ""

# Final summary
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Migration Complete! 🎉                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}Next Steps:${NC}"
echo "1. Test login at your protected services"
echo "2. Login credentials:"
echo "   Username: admin"
echo "   Password: changeme"
echo "   ${RED}⚠️  CHANGE THIS PASSWORD IMMEDIATELY!${NC}"
echo ""
echo "3. Test these URLs:"
echo "   • https://auth.yourdomain.com"
echo "   • https://home.yourdomain.com"
echo "   • https://ha.yourdomain.com"
echo "   • https://request.yourdomain.com"
echo ""
echo "4. Set up 2FA for your admin user"
echo ""
echo "5. After confirming everything works:"
echo "   • Remove old Authentik service:"
echo "     rm -rf /opt/docker/homelab/services/authentik"
echo "   • Remove network:"
echo "     docker network rm authentik-net"
echo ""
echo -e "${YELLOW}Troubleshooting:${NC}"
echo "  View logs: docker logs authelia -f"
echo "  Status: docker ps"
echo "  Test: curl -I http://localhost:9091"
echo ""
echo "See documentation in:"
echo "  /home/coenw/Dev/homelab-docker/services/authelia/README.md"
echo ""





