"""
Configuration for API tests
"""
import os
from datetime import datetime

# API Configuration
API_HOST = os.getenv("API_HOST", "localhost")
API_PORT = os.getenv("API_PORT", "8000")
BASE_URL = f"http://{API_HOST}:{API_PORT}/api/v1"

# Test credentials (from database seeds)
ADMIN_LOGIN = "admin"
ADMIN_PASSWORD = "Admin123!"

EXPERT_LOGIN = "expert1"
EXPERT_PASSWORD = "Expert123!"

TEAM_LOGIN = "team_code_wizards"
TEAM_PASSWORD = "Team123!"

# Output directories
TIMESTAMP = datetime.now().strftime("%Y_%m_%d_%H%M%S")
LOG_DIR = os.path.join(os.path.dirname(__file__), "outputs", "logs")
TOKEN_DIR = os.path.join(os.path.dirname(__file__), "outputs", "tokens")

# Ensure directories exist
os.makedirs(LOG_DIR, exist_ok=True)
os.makedirs(TOKEN_DIR, exist_ok=True)

LOG_FILE = os.path.join(LOG_DIR, f"api_test_{TIMESTAMP}.log")
TOKEN_FILE = os.path.join(TOKEN_DIR, f"tokens_{TIMESTAMP}.json")

# Colors for console output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    MAGENTA = '\033[0;35m'
    NC = '\033[0m'  # No Color