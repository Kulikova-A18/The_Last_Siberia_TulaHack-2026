#!/bin/bash

# ============================================================
# API TEST SCRIPT FOR HACKATHON PLATFORM
# ============================================================
# This script tests all core API endpoints based on TZ.txt
# Results are saved to api_test_YYYY_MM_DD_HHMMSS.log
# ============================================================

# --- Configuration ---
API_HOST=${API_HOST:-"localhost"}
API_PORT=${API_PORT:-"8000"}
BASE_URL="http://${API_HOST}:${API_PORT}/api/v1"
ADMIN_LOGIN="admin"
ADMIN_PASSWORD="Admin123!" # From 02-seed.sql

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Output Files ---
TIMESTAMP=$(date +"%Y_%m_%d_%H%M%S")
LOG_FILE="api_test_${TIMESTAMP}.log"
TOKEN_FILE="tokens_${TIMESTAMP}.json"
TEMP_RESPONSE=".tmp_response_$$.json"

# --- Flags for test results ---
TEST_FAILED=0
CONTINUE_ON_ERROR=true

# --- Helper Functions ---
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_json() {
    if command -v jq &> /dev/null; then
        echo "$1" | jq '.' 2>/dev/null | tee -a "$LOG_FILE" || echo "$1" | tee -a "$LOG_FILE"
    else
        echo "$1" | tee -a "$LOG_FILE"
    fi
}

log_section() {
    echo "" | tee -a "$LOG_FILE"
    echo -e "${BLUE}============================================================${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}>>> $1${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}============================================================${NC}" | tee -a "$LOG_FILE"
}

# Execute curl and capture response
call_api() {
    local method=$1
    local url=$2
    local data=$3
    local token=$4
    
    local auth_header=""
    if [ -n "$token" ] && [ "$token" != "null" ]; then
        auth_header="-H 'Authorization: Bearer $token'"
    fi
    
    log "${YELLOW}> Request:${NC} $method $url"
    if [ -n "$data" ] && [ "$data" != "null" ]; then
        log "${YELLOW}> Body:${NC} $data"
    fi
    
    # Build curl command
    local cmd="curl -s -w '\n%{http_code}' -X $method '$url' -H 'Content-Type: application/json' $auth_header"
    if [ -n "$data" ] && [ "$data" != "null" ]; then
        cmd="$cmd -d '$data'"
    fi
    
    # Execute and capture
    local http_code
    local response_body
    
    # Execute curl and separate body and status code
    local full_response
    full_response=$(eval "$cmd" 2>&1)
    http_code=$(echo "$full_response" | tail -n1)
    response_body=$(echo "$full_response" | sed '$d')
    
    # Log response
    log "${GREEN}< Response (HTTP $http_code):${NC}"
    log_json "$response_body"
    
    # Check if response is valid JSON
    if echo "$response_body" | jq empty 2>/dev/null; then
        echo "$response_body" > "$TEMP_RESPONSE"
    else
        echo "{}" > "$TEMP_RESPONSE"
        log "${YELLOW}Warning: Response is not valid JSON${NC}"
    fi
    
    # Return response body
    echo "$response_body"
}

# Extract value from JSON using jq
extract_json() {
    local json=$1
    local key=$2
    if command -v jq &> /dev/null; then
        echo "$json" | jq -r "$key" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Check if value exists and is not empty
has_value() {
    local value=$1
    if [ -z "$value" ] || [ "$value" == "null" ]; then
        return 1
    fi
    return 0
}

# Cleanup on exit
cleanup() {
    rm -f "$TEMP_RESPONSE"
}
trap cleanup EXIT

# --- Main Test Execution ---
main() {
    log_section "HACKATHON API TEST EXECUTION"
    log "Started at: $(date)"
    log "Base URL: $BASE_URL"
    log "Log file: $LOG_FILE"
    
    # Check dependencies
    if ! command -v curl &> /dev/null; then
        log "${RED}Error: curl is required but not installed.${NC}"
        log "${YELLOW}Please install curl and try again.${NC}"
        return 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log "${YELLOW}Warning: jq is not installed. JSON responses will not be pretty-printed.${NC}"
        log "${YELLOW}Install jq with: sudo apt-get install jq${NC}"
    fi
    
    # Test health endpoint
    log_section "0. HEALTH CHECK"
    call_api "GET" "http://${API_HOST}:${API_PORT}/health" "" ""
    
    # Wait for backend to be ready
    log_section "WAITING FOR BACKEND"
    log "Checking backend readiness..."
    
    local ready=false
    for i in {1..10}; do
        if curl -s -f "http://${API_HOST}:${API_PORT}/health" > /dev/null 2>&1; then
            log "${GREEN}Backend is ready!${NC}"
            ready=true
            break
        fi
        log "Waiting for backend... ($i/10)"
        sleep 2
    done
    
    if [ "$ready" = false ]; then
        log "${YELLOW}Backend health check failed, but continuing anyway...${NC}"
    fi
    
    # ========================================================
    # 1. AUTHENTICATION
    # ========================================================
    log_section "1. AUTHENTICATION"
    
    # Login as admin
    login_data="{\"login\":\"$ADMIN_LOGIN\",\"password\":\"$ADMIN_PASSWORD\"}"
    response=$(call_api "POST" "$BASE_URL/auth/login" "$login_data")
    
    ACCESS_TOKEN=$(extract_json "$response" ".access_token")
    REFRESH_TOKEN=$(extract_json "$response" ".refresh_token")
    ADMIN_USER_ID=$(extract_json "$response" ".user.id")
    
    if ! has_value "$ACCESS_TOKEN"; then
        log "${RED}Failed to obtain access token.${NC}"
        log "${YELLOW}Continuing with limited tests...${NC}"
        ACCESS_TOKEN=""
    else
        log "${GREEN}Access Token obtained: ${ACCESS_TOKEN:0:20}...${NC}"
        
        # Save tokens to file
        echo "{\"access_token\":\"$ACCESS_TOKEN\",\"refresh_token\":\"$REFRESH_TOKEN\",\"user_id\":\"$ADMIN_USER_ID\"}" > "$TOKEN_FILE"
        log "Tokens saved to $TOKEN_FILE"
    fi
    
    # Get current user info
    log_section "1a. GET CURRENT USER INFO"
    call_api "GET" "$BASE_URL/auth/me" "" "$ACCESS_TOKEN"
    
    # Refresh token
    log_section "1b. REFRESH TOKEN"
    if has_value "$REFRESH_TOKEN"; then
        refresh_data="{\"refresh_token\":\"$REFRESH_TOKEN\"}"
        response=$(call_api "POST" "$BASE_URL/auth/refresh" "$refresh_data" "")
        NEW_ACCESS_TOKEN=$(extract_json "$response" ".access_token")
        if has_value "$NEW_ACCESS_TOKEN"; then
            ACCESS_TOKEN="$NEW_ACCESS_TOKEN"
            log "${GREEN}Token refreshed successfully${NC}"
        fi
    fi
    
    # Change password
    log_section "1c. CHANGE PASSWORD"
    change_pass_data="{\"old_password\":\"$ADMIN_PASSWORD\",\"new_password\":\"NewAdmin456!\"}"
    call_api "POST" "$BASE_URL/auth/change-password" "$change_pass_data" "$ACCESS_TOKEN"
    
    # Change back
    change_back_data="{\"old_password\":\"NewAdmin456!\",\"new_password\":\"$ADMIN_PASSWORD\"}"
    call_api "POST" "$BASE_URL/auth/change-password" "$change_back_data" "$ACCESS_TOKEN"
    
    # ========================================================
    # 2. USERS MANAGEMENT
    # ========================================================
    log_section "2. USERS MANAGEMENT"
    
    # List users
    call_api "GET" "$BASE_URL/users/?page=1&page_size=20" "" "$ACCESS_TOKEN"
    
    # ========================================================
    # 3. HACKATHONS
    # ========================================================
    log_section "3. HACKATHONS"
    
    # Get active hackathon
    response=$(call_api "GET" "$BASE_URL/hackathons/active" "" "$ACCESS_TOKEN")
    HACKATHON_ID=$(extract_json "$response" ".id")
    
    # If no active hackathon, try to list all and get first
    if ! has_value "$HACKATHON_ID"; then
        response=$(call_api "GET" "$BASE_URL/hackathons/" "" "$ACCESS_TOKEN")
        HACKATHON_ID=$(extract_json "$response" ".[0].id")
    fi
    
    if has_value "$HACKATHON_ID"; then
        log "${GREEN}Using Hackathon ID: $HACKATHON_ID${NC}"
    else
        log "${YELLOW}No hackathon found. Creating test hackathon...${NC}"
        hackathon_data="{\"title\":\"Test Hackathon ${TIMESTAMP}\",\"description\":\"Automated test hackathon\",\"start_at\":\"2024-06-01T09:00:00Z\",\"end_at\":\"2024-06-03T18:00:00Z\"}"
        response=$(call_api "POST" "$BASE_URL/hackathons/" "$hackathon_data" "$ACCESS_TOKEN")
        HACKATHON_ID=$(extract_json "$response" ".id")
    fi
    
    # Get hackathon details
    if has_value "$HACKATHON_ID"; then
        call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID" "" "$ACCESS_TOKEN"
    fi
    
    # ========================================================
    # 4. TEAMS MANAGEMENT
    # ========================================================
    log_section "4. TEAMS MANAGEMENT"
    
    if has_value "$HACKATHON_ID"; then
        # List teams
        call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/teams?page=1&page_size=20" "" "$ACCESS_TOKEN"
    else
        log "${YELLOW}Skipping team tests - no hackathon ID${NC}"
    fi
    
    # ========================================================
    # 5. CRITERIA MANAGEMENT
    # ========================================================
    log_section "5. CRITERIA MANAGEMENT"
    
    if has_value "$HACKATHON_ID"; then
        call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/criteria" "" "$ACCESS_TOKEN"
    fi
    
    # ========================================================
    # 6. EXPERT ASSIGNMENTS
    # ========================================================
    log_section "6. EXPERT ASSIGNMENTS"
    
    if has_value "$HACKATHON_ID"; then
        call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/assignments" "" "$ACCESS_TOKEN"
    fi
    
    # ========================================================
    # 7. EXPERT EVALUATIONS (Login as expert1)
    # ========================================================
    log_section "7. EXPERT EVALUATIONS"
    
    # Login as expert1 (from seed data)
    expert_login_data="{\"login\":\"expert1\",\"password\":\"Expert123!\"}"
    response=$(call_api "POST" "$BASE_URL/auth/login" "$expert_login_data")
    EXPERT_TOKEN=$(extract_json "$response" ".access_token")
    
    if has_value "$EXPERT_TOKEN"; then
        log "${GREEN}Expert Token obtained${NC}"
        
        if has_value "$HACKATHON_ID"; then
            # Get assigned teams
            response=$(call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/my/assigned-teams" "" "$EXPERT_TOKEN")
            TEAM_ID=$(extract_json "$response" ".items[0].team_id")
            
            if has_value "$TEAM_ID"; then
                # Get evaluation form
                call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/teams/$TEAM_ID/my-evaluation" "" "$EXPERT_TOKEN"
            fi
        fi
    else
        log "${YELLOW}Could not login as expert1. Check if expert1 exists.${NC}"
    fi
    
    # ========================================================
    # 8. RESULTS & LEADERBOARD
    # ========================================================
    log_section "8. RESULTS & LEADERBOARD"
    
    if has_value "$HACKATHON_ID"; then
        call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/results/leaderboard" "" "$ACCESS_TOKEN"
        call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/results/winners?top=3" "" "$ACCESS_TOKEN"
    fi
    
    # ========================================================
    # 9. PUBLIC ENDPOINTS
    # ========================================================
    log_section "9. PUBLIC ENDPOINTS"
    
    if has_value "$HACKATHON_ID"; then
        call_api "GET" "$BASE_URL/public/hackathons/$HACKATHON_ID/leaderboard" "" ""
        call_api "GET" "$BASE_URL/public/hackathons/$HACKATHON_ID/timer" "" ""
        call_api "GET" "$BASE_URL/public/hackathons/$HACKATHON_ID/winners" "" ""
    fi
    
    # ========================================================
    # 10. TEAM CABINET (Login as team)
    # ========================================================
    log_section "10. TEAM CABINET"
    
    # Try to login as team_code_wizards (from seed)
    team_login_data="{\"login\":\"team_code_wizards\",\"password\":\"Team123!\"}"
    response=$(call_api "POST" "$BASE_URL/auth/login" "$team_login_data")
    TEAM_TOKEN=$(extract_json "$response" ".access_token")
    
    if has_value "$TEAM_TOKEN"; then
        log "${GREEN}Team Token obtained${NC}"
    else
        log "${YELLOW}Could not login as team.${NC}"
    fi
    
    # ========================================================
    # 11. LOGOUT
    # ========================================================
    log_section "11. LOGOUT"
    
    if has_value "$REFRESH_TOKEN" && has_value "$ACCESS_TOKEN"; then
        logout_data="{\"refresh_token\":\"$REFRESH_TOKEN\"}"
        call_api "POST" "$BASE_URL/auth/logout" "$logout_data" "$ACCESS_TOKEN"
    fi
    
    # ========================================================
    # SUMMARY
    # ========================================================
    log_section "TEST EXECUTION COMPLETED"
    log "Finished at: $(date)"
    log "Log file: $LOG_FILE"
    
    if [ -f "$TOKEN_FILE" ]; then
        log "Tokens file: $TOKEN_FILE"
    fi
    
    echo "" | tee -a "$LOG_FILE"
    echo -e "${GREEN}============================================================${NC}" | tee -a "$LOG_FILE"
    echo -e "${GREEN}                 ALL TESTS COMPLETED                        ${NC}" | tee -a "$LOG_FILE"
    echo -e "${GREEN}============================================================${NC}" | tee -a "$LOG_FILE"
    
    if has_value "$HACKATHON_ID"; then
        echo "" | tee -a "$LOG_FILE"
        echo -e "${YELLOW}Test Data:${NC}" | tee -a "$LOG_FILE"
        echo "  Hackathon ID: $HACKATHON_ID" | tee -a "$LOG_FILE"
        echo "" | tee -a "$LOG_FILE"
        echo -e "${YELLOW}WebSocket endpoint (manual test):${NC}" | tee -a "$LOG_FILE"
        echo "  wscat -c ws://${API_HOST}:${API_PORT}/api/v1/ws/public/hackathons/$HACKATHON_ID/leaderboard" | tee -a "$LOG_FILE"
    fi
}

# Run main function
main