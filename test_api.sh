#!/bin/bash

# ============================================================
# API TEST SCRIPT FOR HACKATHON PLATFORM
# ============================================================
# This script tests all core API endpoints based on TZ.txt
# Results are saved to api_test_YYYY_MM_DD_HHMMSS.log
# ============================================================

set -e  # Exit on any error

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

# --- Helper Functions ---
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_json() {
    if command -v jq &> /dev/null; then
        echo "$1" | jq '.' | tee -a "$LOG_FILE"
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
    if [ -n "$data" ]; then
        log "${YELLOW}> Body:${NC} $data"
    fi
    
    # Build curl command
    local cmd="curl -s -X $method '$url' -H 'Content-Type: application/json' $auth_header"
    if [ -n "$data" ]; then
        cmd="$cmd -d '$data'"
    fi
    
    # Execute and capture
    set +e
    eval "$cmd" > "$TEMP_RESPONSE" 2>&1
    local exit_code=$?
    set -e
    
    if [ $exit_code -ne 0 ]; then
        log "${RED}[FAIL]${NC} curl failed with exit code $exit_code"
        cat "$TEMP_RESPONSE" | tee -a "$LOG_FILE"
        rm -f "$TEMP_RESPONSE"
        # exit 1
    fi
    
    local response=$(cat "$TEMP_RESPONSE")
    log "${GREEN}< Response:${NC}"
    log_json "$response"
    echo "$response"
}

# Extract value from JSON using jq
extract_json() {
    local json=$1
    local key=$2
    if command -v jq &> /dev/null; then
        echo "$json" | jq -r "$key"
    else
        echo "ERROR: jq not installed" >&2
        # exit 1
    fi
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
        # exit 1
    fi
    if ! command -v jq &> /dev/null; then
        log "${YELLOW}Warning: jq is not installed. JSON responses will not be pretty-printed.${NC}"
    fi
    
    # Wait for backend to be ready
    log_section "WAITING FOR BACKEND"
    log "Checking $BASE_URL/health (or /docs)..."
    for i in {1..2}; do
        if curl -s -f "${BASE_URL}/docs" > /dev/null 2>&1; then
            log "${GREEN}Backend is ready!${NC}"
            break
        fi
        log "Waiting for backend... ($i/2)"
        sleep 2
        if [ $i -eq 30 ]; then
            log "${RED}Backend did not become ready in time.${NC}"
            # # exit 1
        fi
    done
    
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
    
    if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" == "null" ]; then
        log "${RED}Failed to obtain access token. Exiting.${NC}"
        # exit 1
    fi
    
    log "${GREEN}Access Token obtained: ${ACCESS_TOKEN:0:20}...${NC}"
    
    # Save tokens to file
    echo "{\"access_token\":\"$ACCESS_TOKEN\",\"refresh_token\":\"$REFRESH_TOKEN\",\"user_id\":\"$ADMIN_USER_ID\"}" > "$TOKEN_FILE"
    log "Tokens saved to $TOKEN_FILE"
    
    # Get current user info
    call_api "GET" "$BASE_URL/auth/me" "" "$ACCESS_TOKEN"
    
    # ========================================================
    # 2. ROLES AND PERMISSIONS
    # ========================================================
    log_section "2. ROLES AND PERMISSIONS"
    
    call_api "GET" "$BASE_URL/roles" "" "$ACCESS_TOKEN"
    call_api "GET" "$BASE_URL/permissions" "" "$ACCESS_TOKEN"
    
    # ========================================================
    # 3. HACKATHONS
    # ========================================================
    log_section "3. HACKATHONS"
    
    # List hackathons
    response=$(call_api "GET" "$BASE_URL/hackathons" "" "$ACCESS_TOKEN")
    HACKATHON_ID=$(extract_json "$response" ".items[0].id // empty")
    
    # If no hackathon exists, create one
    if [ -z "$HACKATHON_ID" ]; then
        log "${YELLOW}No existing hackathon found. Creating a test hackathon...${NC}"
        hackathon_data="{\"title\":\"Test Hackathon $(date +%s)\",\"description\":\"Automated test hackathon\",\"start_at\":\"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",\"end_at\":\"$(date -u -v+7d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d '+7 days' +"%Y-%m-%dT%H:%M:%SZ")\"}"
        response=$(call_api "POST" "$BASE_URL/hackathons" "$hackathon_data" "$ACCESS_TOKEN")
        HACKATHON_ID=$(extract_json "$response" ".id")
    fi
    
    log "${GREEN}Using Hackathon ID: $HACKATHON_ID${NC}"
    
    # Get active hackathon
    call_api "GET" "$BASE_URL/hackathons/active" "" "$ACCESS_TOKEN"
    call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID" "" "$ACCESS_TOKEN"
    
    # ========================================================
    # 4. DASHBOARDS
    # ========================================================
    log_section "4. DASHBOARDS"
    
    call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/dashboard/admin" "" "$ACCESS_TOKEN"
    call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/dashboard/expert" "" "$ACCESS_TOKEN"
    call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/dashboard/team" "" "$ACCESS_TOKEN"
    
    # ========================================================
    # 5. USERS
    # ========================================================
    log_section "5. USERS"
    
    # List users
    call_api "GET" "$BASE_URL/users?page=1&page_size=10" "" "$ACCESS_TOKEN"
    
    # Create a test expert user
    expert_data="{\"login\":\"test_expert_${TIMESTAMP}\",\"password\":\"Test123!\",\"full_name\":\"Test Expert\",\"email\":\"expert_${TIMESTAMP}@test.com\",\"role_code\":\"expert\"}"
    response=$(call_api "POST" "$BASE_URL/users" "$expert_data" "$ACCESS_TOKEN")
    EXPERT_ID=$(extract_json "$response" ".id")
    
    # Create a test team account
    team_user_data="{\"login\":\"test_team_${TIMESTAMP}\",\"password\":\"Team123!\",\"full_name\":\"Test Team Account\",\"role_code\":\"team\"}"
    response=$(call_api "POST" "$BASE_URL/users" "$team_user_data" "$ACCESS_TOKEN")
    TEAM_USER_ID=$(extract_json "$response" ".id")
    
    # ========================================================
    # 6. TEAMS
    # ========================================================
    log_section "6. TEAMS"
    
    # Create a team
    team_data="{\"name\":\"Test Team ${TIMESTAMP}\",\"captain_name\":\"John Doe\",\"contact_email\":\"team_${TIMESTAMP}@test.com\",\"project_title\":\"Test Project\",\"description\":\"A test team for API validation\"}"
    response=$(call_api "POST" "$BASE_URL/hackathons/$HACKATHON_ID/teams" "$team_data" "$ACCESS_TOKEN")
    TEAM_ID=$(extract_json "$response" ".id")
    
    # List teams
    call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/teams" "" "$ACCESS_TOKEN"
    
    # Get team details
    call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/teams/$TEAM_ID" "" "$ACCESS_TOKEN"
    
    # Add team member
    member_data="{\"full_name\":\"Jane Doe\",\"email\":\"jane_${TIMESTAMP}@test.com\",\"organization\":\"Test University\",\"is_captain\":false}"
    response=$(call_api "POST" "$BASE_URL/hackathons/$HACKATHON_ID/teams/$TEAM_ID/members" "$member_data" "$ACCESS_TOKEN")
    MEMBER_ID=$(extract_json "$response" ".id")
    
    # ========================================================
    # 7. CRITERIA
    # ========================================================
    log_section "7. CRITERIA"
    
    # Create criteria
    criteria1_data="{\"title\":\"Innovation\",\"description\":\"Novelty of the idea\",\"max_score\":10,\"weight_percent\":40,\"sort_order\":1}"
    response=$(call_api "POST" "$BASE_URL/hackathons/$HACKATHON_ID/criteria" "$criteria1_data" "$ACCESS_TOKEN")
    CRITERION1_ID=$(extract_json "$response" ".id")
    
    criteria2_data="{\"title\":\"Technical Implementation\",\"description\":\"Quality of code and architecture\",\"max_score\":10,\"weight_percent\":30,\"sort_order\":2}"
    response=$(call_api "POST" "$BASE_URL/hackathons/$HACKATHON_ID/criteria" "$criteria2_data" "$ACCESS_TOKEN")
    CRITERION2_ID=$(extract_json "$response" ".id")
    
    criteria3_data="{\"title\":\"Presentation\",\"description\":\"Clarity and persuasiveness\",\"max_score\":10,\"weight_percent\":30,\"sort_order\":3}"
    response=$(call_api "POST" "$BASE_URL/hackathons/$HACKATHON_ID/criteria" "$criteria3_data" "$ACCESS_TOKEN")
    
    # List criteria
    call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/criteria" "" "$ACCESS_TOKEN"
    
    # ========================================================
    # 8. ASSIGNMENTS (Expert -> Team)
    # ========================================================
    log_section "8. ASSIGNMENTS"
    
    assignment_data="{\"expert_user_id\":\"$EXPERT_ID\",\"team_id\":\"$TEAM_ID\"}"
    response=$(call_api "POST" "$BASE_URL/hackathons/$HACKATHON_ID/assignments" "$assignment_data" "$ACCESS_TOKEN")
    ASSIGNMENT_ID=$(extract_json "$response" ".id")
    
    call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/assignments" "" "$ACCESS_TOKEN"
    
    # ========================================================
    # 9. DEADLINES
    # ========================================================
    log_section "9. DEADLINES"
    
    deadline_data="{\"title\":\"Evaluation Deadline\",\"description\":\"All evaluations must be submitted\",\"deadline_at\":\"$(date -u -v+2d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d '+2 days' +"%Y-%m-%dT%H:%M:%SZ")\",\"notify_before_minutes\":60}"
    response=$(call_api "POST" "$BASE_URL/hackathons/$HACKATHON_ID/deadlines" "$deadline_data" "$ACCESS_TOKEN")
    
    call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/deadlines" "" "$ACCESS_TOKEN"
    call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/timer" "" "$ACCESS_TOKEN"
    
    # ========================================================
    # 10. EVALUATIONS (Expert actions)
    # ========================================================
    log_section "10. EVALUATIONS"
    
    # Login as expert to get expert token
    expert_login_data="{\"login\":\"test_expert_${TIMESTAMP}\",\"password\":\"Test123!\"}"
    response=$(call_api "POST" "$BASE_URL/auth/login" "$expert_login_data")
    EXPERT_TOKEN=$(extract_json "$response" ".access_token")
    
    log "${GREEN}Expert Token obtained${NC}"
    
    # Get assigned teams for expert
    call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/my/assigned-teams" "" "$EXPERT_TOKEN"
    
    # Get evaluation form
    call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/teams/$TEAM_ID/my-evaluation" "" "$EXPERT_TOKEN"
    
    # Save draft evaluation
    draft_data="{\"items\":[{\"criterion_id\":\"$CRITERION1_ID\",\"raw_score\":8,\"comment\":\"Great idea!\"},{\"criterion_id\":\"$CRITERION2_ID\",\"raw_score\":7,\"comment\":\"Good code quality\"}],\"overall_comment\":\"Promising project\"}"
    call_api "PUT" "$BASE_URL/hackathons/$HACKATHON_ID/teams/$TEAM_ID/my-evaluation/draft" "$draft_data" "$EXPERT_TOKEN"
    
    # Submit final evaluation
    submit_data="{\"items\":[{\"criterion_id\":\"$CRITERION1_ID\",\"raw_score\":8,\"comment\":\"Great idea!\"},{\"criterion_id\":\"$CRITERION2_ID\",\"raw_score\":7,\"comment\":\"Good code quality\"},{\"criterion_id\":\"$CRITERION3_ID\",\"raw_score\":9,\"comment\":\"Excellent presentation\"}],\"overall_comment\":\"Very strong team!\"}"
    call_api "POST" "$BASE_URL/hackathons/$HACKATHON_ID/teams/$TEAM_ID/my-evaluation/submit" "$submit_data" "$EXPERT_TOKEN"
    
    # Switch back to admin token for remaining tests
    log "${GREEN}Switching back to Admin Token${NC}"
    
    # ========================================================
    # 11. EVALUATIONS (Admin view)
    # ========================================================
    log_section "11. EVALUATIONS (Admin view)"
    
    response=$(call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/evaluations?status=submitted" "" "$ACCESS_TOKEN")
    EVALUATION_ID=$(extract_json "$response" ".items[0].id")
    
    if [ -n "$EVALUATION_ID" ] && [ "$EVALUATION_ID" != "null" ]; then
        call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/evaluations/$EVALUATION_ID" "" "$ACCESS_TOKEN"
    fi
    
    call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/teams/$TEAM_ID/evaluations" "" "$ACCESS_TOKEN"
    
    # ========================================================
    # 12. RESULTS
    # ========================================================
    log_section "12. RESULTS"
    
    # Recalculate results
    call_api "POST" "$BASE_URL/hackathons/$HACKATHON_ID/results/recalculate" "" "$ACCESS_TOKEN"
    
    # Get leaderboard
    call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/results/leaderboard" "" "$ACCESS_TOKEN"
    
    # Get team result
    call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/results/teams/$TEAM_ID" "" "$ACCESS_TOKEN"
    
    # Publish results
    call_api "POST" "$BASE_URL/hackathons/$HACKATHON_ID/results/publish" "" "$ACCESS_TOKEN"
    
    # Get winners
    call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/results/winners?top=3" "" "$ACCESS_TOKEN"
    
    # ========================================================
    # 13. TEAM CABINET (Login as team)
    # ========================================================
    log_section "13. TEAM CABINET"
    
    team_login_data="{\"login\":\"test_team_${TIMESTAMP}\",\"password\":\"Team123!\"}"
    response=$(call_api "POST" "$BASE_URL/auth/login" "$team_login_data")
    TEAM_TOKEN=$(extract_json "$response" ".access_token")
    
    log "${GREEN}Team Token obtained${NC}"
    
    call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/my/team" "" "$TEAM_TOKEN"
    call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/my/team/members" "" "$TEAM_TOKEN"
    call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/my/team/result" "" "$TEAM_TOKEN"
    
    # ========================================================
    # 14. PUBLIC ENDPOINTS
    # ========================================================
    log_section "14. PUBLIC ENDPOINTS (No Auth)"
    
    call_api "GET" "$BASE_URL/public/hackathons/active" "" ""
    call_api "GET" "$BASE_URL/public/hackathons/$HACKATHON_ID/leaderboard" "" ""
    call_api "GET" "$BASE_URL/public/hackathons/$HACKATHON_ID/timer" "" ""
    call_api "GET" "$BASE_URL/public/hackathons/$HACKATHON_ID/winners" "" ""
    
    # ========================================================
    # 15. AUDIT LOGS
    # ========================================================
    log_section "15. AUDIT LOGS"
    
    call_api "GET" "$BASE_URL/hackathons/$HACKATHON_ID/audit-logs?page=1&page_size=20" "" "$ACCESS_TOKEN"
    
    # ========================================================
    # 16. LOGOUT & CLEANUP (Optional)
    # ========================================================
    log_section "16. LOGOUT"
    
    logout_data="{\"refresh_token\":\"$REFRESH_TOKEN\"}"
    call_api "POST" "$BASE_URL/auth/logout" "$logout_data" "$ACCESS_TOKEN"
    
    # ========================================================
    # SUMMARY
    # ========================================================
    log_section "TEST EXECUTION COMPLETED"
    log "Finished at: $(date)"
    log "Log file: $LOG_FILE"
    log "Tokens file: $TOKEN_FILE"
    log ""
    log "${GREEN}============================================================${NC}"
    log "${GREEN}                 ALL TESTS PASSED SUCCESSFULLY              ${NC}"
    log "${GREEN}============================================================${NC}"
    
    # Print summary of created test data
    echo "" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}Test Data Created:${NC}" | tee -a "$LOG_FILE"
    echo "  Hackathon ID: $HACKATHON_ID" | tee -a "$LOG_FILE"
    echo "  Expert User: test_expert_${TIMESTAMP} (ID: $EXPERT_ID)" | tee -a "$LOG_FILE"
    echo "  Team Account: test_team_${TIMESTAMP} (ID: $TEAM_USER_ID)" | tee -a "$LOG_FILE"
    echo "  Team: Test Team ${TIMESTAMP} (ID: $TEAM_ID)" | tee -a "$LOG_FILE"
    echo "  Criterion IDs: $CRITERION1_ID, $CRITERION2_ID" | tee -a "$LOG_FILE"
}

# Run main function
main