#!/bin/bash
# Fix the Authentik YAML error and continue migration

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Fixing Authentik YAML error...${NC}"
sudo sed -i 's/depends_on:login/depends_on:/' /opt/docker/homelab/services/authentik/docker-compose.yml
echo -e "${GREEN}✅ Fixed${NC}\n"

echo -e "${YELLOW}Stopping Authentik containers...${NC}"
cd /opt/docker/homelab/services/authentik
docker compose down
echo -e "${GREEN}✅ Authentik stopped${NC}\n"

echo -e "${YELLOW}Starting Authelia...${NC}"
cd /home/coenw/Dev/homelab-docker/services/authelia
docker compose up -d

echo "Waiting for Authelia to start..."
sleep 8

if docker ps | grep -q authelia; then
    echo -e "${GREEN}✅ Authelia started${NC}\n"
    docker logs authelia --tail 15
else
    echo -e "❌ Authelia failed to start"
    docker logs authelia
    exit 1
fi

echo ""
echo -e "${YELLOW}Starting Caddy...${NC}"
cd /opt/docker/homelab/services/public
docker compose up -d

sleep 5

if docker ps | grep -q caddy; then
    echo -e "${GREEN}✅ Caddy started${NC}\n"
else
    echo -e "❌ Caddy failed to start"
    docker logs caddy
    exit 1
fi

echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}    Migration Complete! 🎉${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}\n"

echo "Services running:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "authelia|caddy"

echo ""
echo "Login at: https://auth.yourdomain.com"
echo "Username: admin"
echo "Password: changeme"
echo ""
echo "⚠️  CHANGE PASSWORD AFTER FIRST LOGIN!"
