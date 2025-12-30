#!/bin/bash

####################
# Start Public & Security Stack
####################
# This script starts the public-facing and security services
# Services: public (Caddy + DuckDNS), security (Endlessh), authentik (SSO)

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICES_DIR="$SCRIPT_DIR/../services"

echo -e "${YELLOW}=== Starting Public & Security Stack ===${NC}\n"

# Function to start a service
start_service() {
    local service=$1
    echo -e "${GREEN}Starting $service...${NC}"
    cd "$SERVICES_DIR/$service"
    docker compose up -d
    echo ""
}

# Check if infra is running (required dependency)
echo "Checking infrastructure..."
if ! docker ps | grep -q socky_proxy; then
    echo -e "${YELLOW}Infrastructure not running. Starting infra first...${NC}"
    start_service "infra"
    echo "Waiting 10 seconds for infrastructure to be healthy..."
    sleep 10
fi

# Start services in order
# protonmail-bridge must start before authelia (SMTP dependency)
# authelia needs to start before public (Caddy) if using forward auth
# security can start independently

start_service "protonmail-bridge"

echo -e "${YELLOW}Waiting 5 seconds for Protonmail Bridge...${NC}"
sleep 5

start_service "authelia"

echo -e "${YELLOW}Waiting 10 seconds for Authelia to initialize...${NC}"
sleep 10

start_service "public"
start_service "security"

echo -e "${GREEN}=== Public & Security Stack Started ===${NC}\n"
echo "Running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "authelia|caddy|duckdns|endlessh|socky_proxy|protonmail"

echo -e "\n${GREEN}Services are starting up!${NC}"
echo "Access points:"
echo "  - 🔐 Authelia (SSO):     http://\$SERVER_URL:9091"
echo "  - 🌐 Caddy (Proxy):      http://\$SERVER_URL (admin: :2019)"
echo "  - 🦆 DuckDNS:            (background service)"
echo "  - 🔒 Endlessh (SSH):     Port 22 (tarpit)"
echo ""
echo "For external access through your domain:"
echo "  - https://auth.yourdomain.com    (Authelia)"
echo "  - https://jelly.yourdomain.com   (Jellyfin)"
echo "  - https://home.yourdomain.com    (Homepage)"



