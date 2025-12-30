#!/bin/bash

####################
# Start Media Stack Services
####################
# This script starts the media-related services in the correct order
# Services: adblock-and-dns, downloads, media-streaming, media-request

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICES_DIR="$SCRIPT_DIR/../services"

echo -e "${YELLOW}=== Starting Media Stack ===${NC}\n"

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
# Note: adblock-and-dns can be started independently
# downloads depends on VPN (gluetun) being healthy
# media-streaming and media-request depend on downloads for content

# Start dashboard early so you can monitor everything
start_service "dashboard"

# start_service "adblock-and-dns"
start_service "downloads"

echo -e "${YELLOW}Waiting 15 seconds for VPN (gluetun) to establish connection...${NC}"
sleep 15

start_service "media-streaming"
start_service "media-request"

echo -e "${GREEN}=== Media Stack Started ===${NC}\n"
echo "Running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n${GREEN}Services are starting up!${NC}"
echo "Access points:"
echo "  - 🏠 Homepage Dashboard: http://\$SERVER_URL:3000"
echo ""
echo "  - Jellyfin (Media):      http://\$SERVER_URL:8096"
echo "  - Jellyseerr (Requests): http://\$SERVER_URL:5055"
echo "  - qBittorrent:           http://\$SERVER_URL:8080"
echo "  - Prowlarr (Indexer):    http://\$SERVER_URL:9696"
echo "  - Sonarr (TV):           http://\$SERVER_URL:8989"
echo "  - Radarr (Movies):       http://\$SERVER_URL:7878"
echo "  - Lidarr (Music):        http://\$SERVER_URL:8686"
echo "  - Pi-hole (DNS):         http://\$SERVER_URL/admin"
echo "  - Gluetun Control:       http://\$SERVER_URL:8000"

