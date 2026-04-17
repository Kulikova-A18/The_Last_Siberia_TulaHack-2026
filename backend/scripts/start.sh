# backend/scripts/start.sh
#!/bin/bash

# Backend Startup Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_ROOT="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$BACKEND_ROOT")"

echo -e "${GREEN}Starting HackRank Backend...${NC}"

cd "$BACKEND_ROOT"

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Creating .env file from .env.example...${NC}"
    cp .env.example .env
fi

# Check if database is running
if ! docker ps --format '{{.Names}}' | grep -q "hackathon_postgres"; then
    echo -e "${YELLOW}Database is not running. Starting database first...${NC}"
    cd "$PROJECT_ROOT/database"
    ./scripts/start.sh
    cd "$BACKEND_ROOT"
fi

# Build and start backend
echo -e "${YELLOW}Building and starting backend...${NC}"
docker-compose up -d --build

# Wait for backend to be ready
echo -e "${YELLOW}Waiting for backend to be ready...${NC}"
for i in {1..30}; do
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        echo -e "${GREEN}Backend is ready!${NC}"
        break
    fi
    echo -n "."
    sleep 1
done

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}HackRank Backend Started${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "API URL: ${YELLOW}http://localhost:8000${NC}"
echo -e "API Docs: ${YELLOW}http://localhost:8000/docs${NC}"
echo -e "Redoc: ${YELLOW}http://localhost:8000/redoc${NC}"
echo -e "${GREEN}========================================${NC}"