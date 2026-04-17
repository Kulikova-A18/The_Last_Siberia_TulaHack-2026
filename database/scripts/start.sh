#!/bin/bash

# Hackathon Database Startup Script
# This script initializes and starts PostgreSQL with all configurations

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${PROJECT_ROOT}/.env"

# Load environment variables
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
    echo -e "${GREEN}✓ Loaded environment variables from ${ENV_FILE}${NC}"
else
    echo -e "${YELLOW}⚠ No .env file found, using defaults${NC}"
    export POSTGRES_USER=${POSTGRES_USER:-hackathon_admin}
    export POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-SecurePass123!}
    export POSTGRES_DB=${POSTGRES_DB:-hackathon_db}
    export POSTGRES_PORT=${POSTGRES_PORT:-5432}
fi

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}✗ Docker is not running. Please start Docker first.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Docker is running${NC}"
}

# Function to check if ports are available
check_ports() {
    if lsof -Pi :$POSTGRES_PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo -e "${RED}✗ Port $POSTGRES_PORT is already in use${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Port $POSTGRES_PORT is available${NC}"
}

# Function to create necessary directories
create_directories() {
    mkdir -p "${PROJECT_ROOT}/data"
    mkdir -p "${PROJECT_ROOT}/logs"
    mkdir -p "${PROJECT_ROOT}/backups"
    echo -e "${GREEN}✓ Created necessary directories${NC}"
}

# Function to start PostgreSQL
start_postgres() {
    echo -e "${YELLOW}Starting PostgreSQL...${NC}"
    
    cd "$PROJECT_ROOT"
    docker-compose up -d postgres
    
    # Wait for PostgreSQL to be ready
    echo -e "${YELLOW}Waiting for PostgreSQL to be ready...${NC}"
    sleep 5
    
    # Health check
    for i in {1..30}; do
        if docker exec hackathon_postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ PostgreSQL is ready${NC}"
            return 0
        fi
        echo -n "."
        sleep 1
    done
    
    echo -e "\n${RED}✗ PostgreSQL failed to start${NC}"
    docker-compose logs postgres
    exit 1
}

# Function to start pgAdmin
start_pgadmin() {
    echo -e "${YELLOW}Starting pgAdmin...${NC}"
    docker-compose up -d pgadmin
    echo -e "${GREEN}✓ pgAdmin started on port ${PGADMIN_PORT:-5050}${NC}"
}

# Function to show connection info
show_connection_info() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}PostgreSQL Connection Information${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "Host: ${YELLOW}localhost${NC}"
    echo -e "Port: ${YELLOW}$POSTGRES_PORT${NC}"
    echo -e "Database: ${YELLOW}$POSTGRES_DB${NC}"
    echo -e "User: ${YELLOW}$POSTGRES_USER${NC}"
    echo -e "Password: ${YELLOW}$POSTGRES_PASSWORD${NC}"
    echo ""
    echo -e "Connection string:"
    echo -e "${YELLOW}postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@localhost:$POSTGRES_PORT/$POSTGRES_DB${NC}"
    echo ""
    echo -e "pgAdmin URL: ${YELLOW}http://localhost:${PGADMIN_PORT:-5050}${NC}"
    echo -e "pgAdmin Email: ${YELLOW}${PGADMIN_EMAIL:-admin@hackathon.com}${NC}"
    echo -e "pgAdmin Password: ${YELLOW}${PGADMIN_PASSWORD:-admin123}${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# Function to verify database
verify_database() {
    echo -e "${YELLOW}Verifying database setup...${NC}"
    
    # Check tables
    TABLES=$(docker exec hackathon_postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
    echo -e "${GREEN}✓ Created $TABLES tables${NC}"
    
    # Check roles
    ROLES=$(docker exec hackathon_postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM roles;")
    echo -e "${GREEN}✓ Loaded $ROLES roles${NC}"
    
    # Check permissions
    PERMS=$(docker exec hackathon_postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM permissions;")
    echo -e "${GREEN}✓ Loaded $PERMS permissions${NC}"
}

# Main execution
main() {
    echo -e "${GREEN}Starting Hackathon Database...${NC}"
    echo ""
    
    check_docker
    check_ports
    create_directories
    start_postgres
    start_pgadmin
    verify_database
    show_connection_info
    
    echo -e "${GREEN}✓ Database started successfully!${NC}"
}

# Run main function
main