#!/bin/bash

# Hackathon Database Stop Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${YELLOW}Stopping Hackathon Database...${NC}"

cd "$PROJECT_ROOT"

if docker-compose ps > /dev/null 2>&1; then
    docker-compose down
    echo -e "${GREEN}Database containers stopped${NC}"
else
    echo -e "${RED}No running containers found${NC}"
fi

echo -e "${GREEN}Database stopped successfully!${NC}"