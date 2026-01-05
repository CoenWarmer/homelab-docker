#!/bin/bash

####################
# Stop Media Stack Services
####################
# This script stops the media-related services in reverse order

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICES_DIR="$SCRIPT_DIR/../services"

echo -e "${YELLOW}=== Stopping Media Stack ===${NC}\n"

# Function to stop a service
stop_service() {
    local service=$1
    echo -e "${GREEN}Stopping $service...${NC}"
    cd "$SERVICES_DIR/$service"
    docker compose down
    echo ""
}

# Stop services in reverse order
stop_service "media-request"
stop_service "media-streaming"
stop_service "downloads"
stop_service "adblock-and-dns"

echo -e "${GREEN}=== Media Stack Stopped ===${NC}\n"
docker ps --format "table {{.Names}}\t{{.Status}}"












