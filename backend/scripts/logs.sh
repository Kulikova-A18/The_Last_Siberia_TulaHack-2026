# backend/scripts/logs.sh
#!/bin/bash

# Backend Logs Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$BACKEND_ROOT"

docker-compose logs -f --tail=100