# backend/scripts/restart.sh
#!/bin/bash

# Backend Restart Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Restarting HackRank Backend..."

bash "$SCRIPT_DIR/stop.sh"
bash "$SCRIPT_DIR/start.sh"

echo "Backend restarted successfully!"