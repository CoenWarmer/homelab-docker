#!/bin/bash

####################
# Stop Public & Security Stack
####################
# This script stops the public-facing and security services in reverse order

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICES_DIR="$SCRIPT_DIR/../services"

echo -e "${YELLOW}=== Stopping Public & Security Stack ===${NC}\n"

# Function to stop a service
stop_service() {
    local service=$1
    echo -e "${GREEN}Stopping $service...${NC}"
    cd "$SERVICES_DIR/$service"
    docker compose down
    echo ""
}

# Stop services in reverse order
stop_service "security"
stop_service "public"
stop_service "authelia"

echo -e "${GREEN}=== Public & Security Stack Stopped ===${NC}\n"
docker ps --format "table {{.Names}}\t{{.Status}}"



