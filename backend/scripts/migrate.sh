# backend/scripts/migrate.sh
#!/bin/bash

# Database Migration Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$BACKEND_ROOT"

echo -e "${YELLOW}Running database migrations...${NC}"

# Check if alembic is initialized
if [ ! -d "alembic/versions" ]; then
    echo -e "${YELLOW}Initializing alembic...${NC}"
    alembic init alembic
fi

# Generate migration
echo -e "${YELLOW}Generating migration...${NC}"
alembic revision --autogenerate -m "auto_migration"

# Apply migration
echo -e "${YELLOW}Applying migration...${NC}"
alembic upgrade head

echo -e "${GREEN}Migrations completed successfully!${NC}"