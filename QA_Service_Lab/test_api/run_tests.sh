#!/bin/bash

# Run API tests

cd "$(dirname "$0")"

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo "ERROR: python3 is not installed"
    exit 1
fi

# Function to get primary IP address
get_primary_ip() {
    # Try different methods to get the primary IP
    
    # Method 1: Get IP of default route interface (Linux)
    if command -v ip &> /dev/null; then
        DEFAULT_IP=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+')
        if [ -n "$DEFAULT_IP" ] && [ "$DEFAULT_IP" != "127.0.0.1" ]; then
            echo "$DEFAULT_IP"
            return 0
        fi
    fi
    
    # Method 2: Get first non-loopback IPv4 address
    if command -v hostname &> /dev/null; then
        HOST_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
        if [ -n "$HOST_IP" ] && [ "$HOST_IP" != "127.0.0.1" ]; then
            echo "$HOST_IP"
            return 0
        fi
    fi
    
    # Method 3: Use ifconfig (older systems)
    if command -v ifconfig &> /dev/null; then
        IF_CONFIG_IP=$(ifconfig 2>/dev/null | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n1)
        if [ -n "$IF_CONFIG_IP" ]; then
            echo "$IF_CONFIG_IP"
            return 0
        fi
    fi
    
    # Method 4: macOS
    if command -v ifconfig &> /dev/null; then
        MAC_IP=$(ifconfig en0 2>/dev/null | grep 'inet ' | awk '{print $2}')
        if [ -n "$MAC_IP" ]; then
            echo "$MAC_IP"
            return 0
        fi
    fi
    
    # Fallback to localhost
    echo "localhost"
    return 1
}

# Get primary IP
PRIMARY_IP=$(get_primary_ip)

# Clean old virtual environment if exists
if [ -d "venv" ]; then
    echo "Removing old virtual environment..."
    rm -rf venv
fi

# Create virtual environment
echo "Creating virtual environment..."
python3 -m venv venv

# Activate virtual environment
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
elif [ -f "venv/Scripts/activate" ]; then
    # Windows (Git Bash, etc.)
    source venv/Scripts/activate
else
    echo "ERROR: Could not find virtual environment activation script"
    exit 1
fi

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip -q

# Install requirements
echo "Installing requirements..."
pip install -r requirements.txt -q

# Set default API host if not set
# Priority: Environment variable > Primary IP > localhost
if [ -z "$API_HOST" ]; then
    if [ "$PRIMARY_IP" != "localhost" ] && [ -n "$PRIMARY_IP" ]; then
        export API_HOST="$PRIMARY_IP"
        echo "Auto-detected API host: $API_HOST"
    else
        export API_HOST="localhost"
        echo "Using default API host: $API_HOST"
    fi
else
    echo "Using provided API host: $API_HOST"
fi

export API_PORT=${API_PORT:-"8000"}

echo "============================================================"
echo "System Information:"
echo "  Primary IP: $PRIMARY_IP"
echo "  API Host:   $API_HOST"
echo "  API Port:   $API_PORT"
echo "============================================================"

# Run tests
python3 test_runner.py

# Save exit code
TEST_EXIT_CODE=$?

# Deactivate virtual environment
deactivate 2>/dev/null || true

echo ""
echo "============================================================"
echo "Test execution completed with exit code: $TEST_EXIT_CODE"
echo "============================================================"

# Print summary based on health check
if [ "$HEALTH_STATUS" = "FAILED" ]; then
    echo ""
    echo "WARNING: API health check failed. Tests may have been limited."
    echo "Please ensure the backend is running:"
    echo "  cd /path/to/project && sudo docker-compose up -d"
fi

exit $TEST_EXIT_CODE