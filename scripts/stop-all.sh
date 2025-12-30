#!/bin/bash

####################
# Stop All Homelab Services
####################

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Stopping All Homelab Services ===${NC}\n"

# Stop all running containers
docker stop $(docker ps -q) 2>/dev/null

echo -e "\n${GREEN}=== All Services Stopped ===${NC}"


