#!/bin/bash

####################
# Start All Homelab Services
####################
# This script starts all homelab services in the correct order

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}=== Starting Complete Homelab Stack ===${NC}\n"

# Start infrastructure first
echo -e "${GREEN}Step 1: Starting Infrastructure...${NC}"
cd "$SCRIPT_DIR/../services/infra"
docker compose up -d
sleep 10

# Start public and security services
echo -e "\n${GREEN}Step 2: Starting Public & Security Services...${NC}"
bash "$SCRIPT_DIR/start-public-stack.sh"

# Start media services
echo -e "\n${GREEN}Step 3: Starting Media Services...${NC}"
bash "$SCRIPT_DIR/start-media-stack.sh"

# Start monitoring services
echo -e "\n${GREEN}Step 4: Starting Monitoring Services...${NC}"
cd "$SCRIPT_DIR/../services/monitor"
docker compose up -d

# Start file browser 
echo -e "\n${GREEN}Step 5: Starting File Browser...${NC}"
cd "$SCRIPT_DIR/../services/filebrowser"
docker compose up -d

# Start home assistant if not already running
echo -e "\n${GREEN}Step 6: Starting Home Automation...${NC}"
cd "$SCRIPT_DIR/../services/home-assistant"
docker compose up -d

# Start Immich (photo management)
echo -e "\n${GREEN}Step 7: Starting Immich...${NC}"
cd "$SCRIPT_DIR/../services/immich"
docker compose up -d

# Start iCloud Photos Downloader
echo -e "\n${GREEN}Step 8: Starting iCloud Photos Downloader...${NC}"
cd "$SCRIPT_DIR/../services/icloudpd"
docker compose up -d

echo -e "\n${GREEN}=== Complete Homelab Stack Started ===${NC}\n"
echo "All services should now be running!"
echo ""
echo "Main access points:"
echo "  - 🏠 Homepage Dashboard: http://\$SERVER_URL:3000"
echo "  - 🔐 Authelia (SSO):     http://\$SERVER_URL:9091"
echo "  - 🏡 Home Assistant:     http://\$SERVER_URL:8123"
echo "  - 📊 Dozzle (Logs):      http://\$SERVER_URL:\$PORT_DOZZLE"
echo "  - 📡 Signal API:         http://\$SERVER_URL:\$PORT_SIGNAL_API"
echo ""
echo "Check status with: docker ps"



