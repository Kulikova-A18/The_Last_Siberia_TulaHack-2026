#!/bin/bash

# PostgreSQL Health Check Script

set -e

export PGPASSWORD="${POSTGRES_PASSWORD:-SecurePass123!}"

# Check if PostgreSQL is accepting connections
if psql -h localhost -U "${POSTGRES_USER:-hackathon_admin}" -d "${POSTGRES_DB:-hackathon_db}" -c "SELECT 1" > /dev/null 2>&1; then
    # Check if all required tables exist
    TABLES_COUNT=$(psql -h localhost -U "${POSTGRES_USER:-hackathon_admin}" -d "${POSTGRES_DB:-hackathon_db}" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('users', 'teams', 'criteria', 'evaluations');")
    
    if [ "$TABLES_COUNT" -eq 4 ]; then
        exit 0
    else
        echo "Missing required tables"
        exit 1
    fi
else
    echo "PostgreSQL is not responding"
    exit 1
fi