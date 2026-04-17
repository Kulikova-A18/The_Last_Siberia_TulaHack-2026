#!/bin/bash

# Hackathon Database Backup Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${PROJECT_ROOT}/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/hackathon_db_${TIMESTAMP}.sql"

# Load environment variables
if [ -f "${PROJECT_ROOT}/.env" ]; then
    source "${PROJECT_ROOT}/.env"
fi

export POSTGRES_USER=${POSTGRES_USER:-hackathon_admin}
export POSTGRES_DB=${POSTGRES_DB:-hackathon_db}

mkdir -p "$BACKUP_DIR"

echo -e "${YELLOW}Creating database backup...${NC}"

# Create backup
docker exec hackathon_postgres pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" > "$BACKUP_FILE"

if [ -f "$BACKUP_FILE" ]; then
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo -e "${GREEN}Backup created: ${BACKUP_FILE} (${SIZE})${NC}"
    
    # Compress backup
    gzip "$BACKUP_FILE"
    echo -e "${GREEN}Backup compressed: ${BACKUP_FILE}.gz${NC}"
    
    # Keep only last 10 backups
    cd "$BACKUP_DIR"
    ls -t hackathon_db_*.sql.gz 2>/dev/null | tail -n +11 | xargs -r rm
    echo -e "${GREEN}Cleaned old backups (kept last 10)${NC}"
else
    echo -e "${RED}Backup failed${NC}"
    exit 1
fi