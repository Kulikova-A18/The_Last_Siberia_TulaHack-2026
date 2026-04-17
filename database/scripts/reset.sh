#!/bin/bash

# Hackathon Database Reset Script
# WARNING: This will delete all data!

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${RED}⚠ WARNING: This will delete ALL database data!${NC}"
read -p "Are you sure you want to continue? (yes/no): " -r

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${YELLOW}Reset cancelled${NC}"
    exit 0
fi

echo -e "${YELLOW}Resetting database...${NC}"

cd "$PROJECT_ROOT"

# Stop and remove containers
docker-compose down -v

# Remove volumes
docker volume rm hackathon_postgres_data 2>/dev/null || true

# Remove data directory
rm -rf "${PROJECT_ROOT}/data" 2>/dev/null || true

# Start fresh
bash scripts/start.sh

echo -e "${GREEN}✓ Database reset successfully!${NC}"