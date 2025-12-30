#!/bin/bash

####################
# Search Missing Media
####################
# This script triggers a search for all missing movies and TV episodes
# in Radarr and Sonarr. Run via cron for automatic retry searches.
#
# Usage: ./search-missing-media.sh
# Recommended cron: 0 4 * * * /opt/docker/homelab-docker/scripts/search-missing-media.sh

set -e

# Load specific variables from .env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

get_env_var() {
    grep "^$1=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 | sed 's/#.*//' | tr -d ' '
}

# Configuration
RADARR_URL=$(get_env_var "SERVER_URL")
RADARR_PORT=$(get_env_var "PORT_RADARR_UI")
RADARR_API_KEY=$(get_env_var "HOMEPAGE_RADARR_API")

SONARR_URL=$(get_env_var "SERVER_URL")
SONARR_PORT=$(get_env_var "PORT_SONARR_UI")
SONARR_API_KEY=$(get_env_var "HOMEPAGE_SONARR_API")

# Defaults
RADARR_URL="${RADARR_URL:-localhost}"
RADARR_PORT="${RADARR_PORT:-7878}"
SONARR_URL="${SONARR_URL:-localhost}"
SONARR_PORT="${SONARR_PORT:-8989}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Search missing movies in Radarr
search_radarr() {
    log "${YELLOW}Triggering Radarr missing movies search...${NC}"
    
    response=$(curl -s -X POST "http://${RADARR_URL}:${RADARR_PORT}/api/v3/command" \
        -H "X-Api-Key: ${RADARR_API_KEY}" \
        -H "Content-Type: application/json" \
        -d '{"name": "MissingMoviesSearch"}' \
        -w "\n%{http_code}")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "201" ]; then
        log "${GREEN}✓ Radarr: Missing movies search started${NC}"
    else
        log "${RED}✗ Radarr: Failed to start search (HTTP $http_code)${NC}"
        echo "$body"
    fi
}

# Search missing episodes in Sonarr
search_sonarr() {
    log "${YELLOW}Triggering Sonarr missing episodes search...${NC}"
    
    response=$(curl -s -X POST "http://${SONARR_URL}:${SONARR_PORT}/api/v3/command" \
        -H "X-Api-Key: ${SONARR_API_KEY}" \
        -H "Content-Type: application/json" \
        -d '{"name": "MissingEpisodeSearch"}' \
        -w "\n%{http_code}")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "201" ]; then
        log "${GREEN}✓ Sonarr: Missing episodes search started${NC}"
    else
        log "${RED}✗ Sonarr: Failed to start search (HTTP $http_code)${NC}"
        echo "$body"
    fi
}

# Main
log "${GREEN}=== Starting Missing Media Search ===${NC}"

if [ -n "$RADARR_API_KEY" ]; then
    search_radarr
else
    log "${RED}✗ Radarr API key not found${NC}"
fi

if [ -n "$SONARR_API_KEY" ]; then
    search_sonarr
else
    log "${RED}✗ Sonarr API key not found${NC}"
fi

log "${GREEN}=== Search commands sent ===${NC}"

