# backend/scripts/stop.sh
#!/bin/bash

# Backend Stop Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${YELLOW}Stopping HackRank Backend...${NC}"

cd "$BACKEND_ROOT"

docker-compose down

echo -e "${GREEN}Backend stopped successfully!${NC}"