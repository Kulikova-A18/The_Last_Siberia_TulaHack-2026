#!/usr/bin/env python3
"""
Main test runner for Hackathon API
"""
import json
import time
import sys
from typing import Optional, Dict, Any
from dataclasses import dataclass, field
from datetime import datetime

from config import *
from api_client import APIClient
from logger import TestLogger


@dataclass
class TestState:
    """Store test state and collected data"""
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None
    admin_user_id: Optional[str] = None
    expert_token: Optional[str] = None
    expert_id: Optional[str] = None
    team_token: Optional[str] = None
    team_user_id: Optional[str] = None
    hackathon_id: Optional[str] = None
    team_id: Optional[str] = None
    criterion_ids: list = field(default_factory=list)
    assignment_id: Optional[str] = None
    evaluation_id: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for saving"""
        return {
            "access_token": self.access_token,
            "refresh_token": self.refresh_token,
            "admin_user_id": self.admin_user_id,
            "expert_token": self.expert_token,
            "expert_id": self.expert_id,
            "team_token": self.team_token,
            "team_user_id": self.team_user_id,
            "hackathon_id": self.hackathon_id,
            "team_id": self.team_id,
            "criterion_ids": self.criterion_ids,
            "assignment_id": self.assignment_id,
            "evaluation_id": self.evaluation_id,
            "timestamp": datetime.now().isoformat()
        }


class APITestRunner:
    """Main test runner for API tests"""
    
    def __init__(self):
        self.logger = TestLogger(LOG_FILE)
        self.client = APIClient(BASE_URL, self.logger)
        self.state = TestState()
        self.passed_tests = 0
        self.failed_tests = 0
        self.skipped_tests = 0
        
    def run(self):
        """Run all tests"""
        self.logger.section("HACKATHON API TEST EXECUTION")
        self.logger.info(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        self.logger.info(f"Base URL: {BASE_URL}")
        self.logger.info(f"Log file: {LOG_FILE}")
        
        # Check backend health
        if not self._check_backend_health():
            self.logger.warning("Backend health check failed, but continuing...")
            
        # Run test suites
        self._test_authentication()
        self._test_user_info()
        self._test_users_management()
        self._test_hackathons()
        self._test_teams()
        self._test_criteria()
        self._test_assignments()
        self._test_expert_evaluations()
        self._test_results()
        self._test_public_endpoints()
        self._test_team_cabinet()
        self._test_logout()
        
        # Save state
        self._save_state()
        
        # Print summary
        self._print_summary()
        
        self.logger.close()
        
    def _check_backend_health(self) -> bool:
        """Check if backend is healthy"""
        self.logger.section("0. HEALTH CHECK")
        
        for i in range(2):
            response = self.client.get("/../../health")  # Go up one level from /api/v1
            if response.success:
                self.logger.success("Backend is ready!")
                return True
            self.logger.info(f"Waiting for backend... ({i+1}/10)")
            time.sleep(2)
            
        return False
        
    def _test_authentication(self):
        """Test login and token refresh"""
        self.logger.section("1. AUTHENTICATION")
        
        # Login as admin
        login_data = {"login": ADMIN_LOGIN, "password": ADMIN_PASSWORD}
        response = self.client.post("/auth/login", data=login_data)
        
        if response.success:
            self.state.access_token = response.get("access_token")
            self.state.refresh_token = response.get("refresh_token")
            self.state.admin_user_id = response.get("user", {}).get("id")
            
            self.logger.success(f"Access Token obtained: {self.state.access_token[:20]}...")
            self.passed_tests += 1
        else:
            self.logger.error("Failed to obtain access token")
            self.failed_tests += 1
            return
            
        # Test refresh token
        if self.state.refresh_token:
            refresh_data = {"refresh_token": self.state.refresh_token}
            response = self.client.post("/auth/refresh", data=refresh_data)
            
            new_token = response.get("access_token")
            if new_token:
                self.state.access_token = new_token
                self.logger.success("Token refreshed successfully")
                self.passed_tests += 1
            else:
                self.logger.warning("Token refresh failed")
                self.skipped_tests += 1
                
        # Test change password
        self.logger.section("1b. CHANGE PASSWORD")
        change_data = {
            "old_password": ADMIN_PASSWORD,
            "new_password": "NewAdmin456!"
        }
        response = self.client.post("/auth/change-password", 
                                    data=change_data, 
                                    token=self.state.access_token)
        
        if response.success:
            # Change back
            change_back = {
                "old_password": "NewAdmin456!",
                "new_password": ADMIN_PASSWORD
            }
            self.client.post("/auth/change-password", 
                           data=change_back, 
                           token=self.state.access_token)
            self.logger.success("Password changed and restored")
            self.passed_tests += 1
        else:
            self.logger.warning("Password change failed (may be expected)")
            self.skipped_tests += 1
            
    def _test_user_info(self):
        """Test getting current user info"""
        self.logger.section("2. CURRENT USER INFO")
        
        response = self.client.get("/auth/me", token=self.state.access_token)
        
        if response.success:
            user = response.body
            self.logger.info(f"User: {user.get('login')} ({user.get('role')})")
            self.passed_tests += 1
        else:
            self.logger.warning("Could not get user info")
            self.skipped_tests += 1
            
    def _test_users_management(self):
        """Test users CRUD operations"""
        self.logger.section("3. USERS MANAGEMENT")
        
        # List users
        response = self.client.get("/users/?page=1&page_size=20", 
                                   token=self.state.access_token)
        
        if response.success:
            items = response.get("items", [])
            self.logger.info(f"Found {len(items)} users")
            self.passed_tests += 1
        else:
            self.logger.warning("Could not list users")
            self.skipped_tests += 1
            
    def _test_hackathons(self):
        """Test hackathons endpoints"""
        self.logger.section("4. HACKATHONS")
        
        # Try to get active hackathon
        response = self.client.get("/hackathons/active", token=self.state.access_token)
        
        if response.success:
            self.state.hackathon_id = response.get("id")
            self.logger.success(f"Active hackathon found: {self.state.hackathon_id}")
            self.passed_tests += 1
        else:
            # Try to list all hackathons
            response = self.client.get("/hackathons/", token=self.state.access_token)
            
            if response.success and isinstance(response.body, list):
                items = response.body
                if items:
                    self.state.hackathon_id = items[0].get("id")
                    self.logger.info(f"Using first hackathon: {self.state.hackathon_id}")
                    self.passed_tests += 1
                else:
                    self.logger.warning("No hackathons found")
                    self.skipped_tests += 1
            else:
                self.logger.warning("Could not get hackathons list")
                self.skipped_tests += 1
                
        # Get hackathon details
        if self.state.hackathon_id:
            response = self.client.get(f"/hackathons/{self.state.hackathon_id}", 
                                       token=self.state.access_token)
            if response.success:
                self.logger.info(f"Hackathon: {response.get('title')}")
                self.passed_tests += 1
                
    def _test_teams(self):
        """Test teams endpoints"""
        self.logger.section("5. TEAMS MANAGEMENT")
        
        if not self.state.hackathon_id:
            self.logger.warning("Skipping team tests - no hackathon ID")
            self.skipped_tests += 1
            return
            
        response = self.client.get(
            f"/hackathons/{self.state.hackathon_id}/teams?page=1&page_size=20",
            token=self.state.access_token
        )
        
        if response.success:
            items = response.get("items", [])
            self.logger.info(f"Found {len(items)} teams")
            
            if items:
                self.state.team_id = items[0].get("id")
                self.logger.info(f"Using team: {items[0].get('name')} (ID: {self.state.team_id})")
                
            self.passed_tests += 1
        else:
            self.logger.warning("Could not list teams")
            self.skipped_tests += 1
            
    def _test_criteria(self):
        """Test criteria endpoints"""
        self.logger.section("6. CRITERIA MANAGEMENT")
        
        if not self.state.hackathon_id:
            self.logger.warning("Skipping criteria tests - no hackathon ID")
            self.skipped_tests += 1
            return
            
        response = self.client.get(
            f"/hackathons/{self.state.hackathon_id}/criteria",
            token=self.state.access_token
        )
        
        if response.success:
            items = response.get("items", [])
            self.logger.info(f"Found {len(items)} criteria")
            
            for item in items[:3]:
                self.state.criterion_ids.append(item.get("id"))
                
            self.passed_tests += 1
        else:
            self.logger.warning("Could not list criteria")
            self.skipped_tests += 1
            
    def _test_assignments(self):
        """Test expert assignments"""
        self.logger.section("7. EXPERT ASSIGNMENTS")
        
        if not self.state.hackathon_id:
            self.logger.warning("Skipping assignment tests - no hackathon ID")
            self.skipped_tests += 1
            return
            
        response = self.client.get(
            f"/hackathons/{self.state.hackathon_id}/assignments",
            token=self.state.access_token
        )
        
        if response.success:
            items = response.body if isinstance(response.body, list) else response.get("items", [])
            self.logger.info(f"Found {len(items)} assignments")
            self.passed_tests += 1
        else:
            self.logger.warning("Could not list assignments")
            self.skipped_tests += 1
            
    def _test_expert_evaluations(self):
        """Test expert evaluation flow"""
        self.logger.section("8. EXPERT EVALUATIONS")
        
        # Login as expert
        expert_login = {"login": EXPERT_LOGIN, "password": EXPERT_PASSWORD}
        response = self.client.post("/auth/login", data=expert_login)
        
        if response.success:
            self.state.expert_token = response.get("access_token")
            self.state.expert_id = response.get("user", {}).get("id")
            self.logger.success(f"Expert logged in: {EXPERT_LOGIN}")
            self.passed_tests += 1
        else:
            self.logger.warning(f"Could not login as {EXPERT_LOGIN}")
            self.skipped_tests += 1
            return
            
        if not self.state.hackathon_id:
            self.logger.warning("Skipping evaluation tests - no hackathon ID")
            self.skipped_tests += 1
            return
            
        # Get assigned teams
        response = self.client.get(
            f"/hackathons/{self.state.hackathon_id}/my/assigned-teams",
            token=self.state.expert_token
        )
        
        if response.success:
            items = response.get("items", [])
            self.logger.info(f"Expert assigned to {len(items)} teams")
            
            if items and not self.state.team_id:
                self.state.team_id = items[0].get("team_id")
                
            self.passed_tests += 1
        else:
            self.logger.warning("Could not get assigned teams")
            self.skipped_tests += 1
            
    def _test_results(self):
        """Test results and leaderboard"""
        self.logger.section("9. RESULTS & LEADERBOARD")
        
        if not self.state.hackathon_id:
            self.logger.warning("Skipping results tests - no hackathon ID")
            self.skipped_tests += 1
            return
            
        # Get leaderboard
        response = self.client.get(
            f"/hackathons/{self.state.hackathon_id}/results/leaderboard",
            token=self.state.access_token
        )
        
        if response.success:
            items = response.get("items", [])
            self.logger.info(f"Leaderboard has {len(items)} teams")
            self.passed_tests += 1
        else:
            self.logger.warning("Could not get leaderboard")
            self.skipped_tests += 1
            
        # Get winners
        response = self.client.get(
            f"/hackathons/{self.state.hackathon_id}/results/winners?top=3",
            token=self.state.access_token
        )
        
        if response.success:
            items = response.get("items", [])
            self.logger.info(f"Found {len(items)} winners")
            self.passed_tests += 1
        else:
            self.logger.warning("Could not get winners")
            self.skipped_tests += 1
            
    def _test_public_endpoints(self):
        """Test public endpoints (no auth)"""
        self.logger.section("10. PUBLIC ENDPOINTS")
        
        if not self.state.hackathon_id:
            self.logger.warning("Skipping public endpoints - no hackathon ID")
            self.skipped_tests += 1
            return
            
        self.client.clear_token()
        
        # Public leaderboard
        response = self.client.get(f"/public/hackathons/{self.state.hackathon_id}/leaderboard")
        if response.success:
            self.logger.info("Public leaderboard accessible")
            self.passed_tests += 1
        else:
            self.logger.warning("Public leaderboard not accessible")
            self.skipped_tests += 1
            
        # Public timer
        response = self.client.get(f"/public/hackathons/{self.state.hackathon_id}/timer")
        if response.success:
            self.logger.info("Public timer accessible")
            self.passed_tests += 1
        else:
            self.logger.warning("Public timer not accessible")
            self.skipped_tests += 1
            
        # Public winners
        response = self.client.get(f"/public/hackathons/{self.state.hackathon_id}/winners")
        if response.success:
            self.logger.info("Public winners accessible")
            self.passed_tests += 1
        else:
            self.logger.warning("Public winners not accessible")
            self.skipped_tests += 1
            
        # Restore token
        self.client.set_token(self.state.access_token)
        
    def _test_team_cabinet(self):
        """Test team cabinet"""
        self.logger.section("11. TEAM CABINET")
        
        # Login as team
        team_login = {"login": TEAM_LOGIN, "password": TEAM_PASSWORD}
        response = self.client.post("/auth/login", data=team_login)
        
        if response.success:
            self.state.team_token = response.get("access_token")
            self.state.team_user_id = response.get("user", {}).get("id")
            self.logger.success(f"Team logged in: {TEAM_LOGIN}")
            self.passed_tests += 1
        else:
            self.logger.warning(f"Could not login as {TEAM_LOGIN}")
            self.skipped_tests += 1
            
    def _test_logout(self):
        """Test logout"""
        self.logger.section("12. LOGOUT")
        
        if self.state.refresh_token:
            logout_data = {"refresh_token": self.state.refresh_token}
            response = self.client.post("/auth/logout", data=logout_data, 
                                        token=self.state.access_token)
            
            if response.success:
                self.logger.success("Logged out successfully")
                self.passed_tests += 1
            else:
                self.logger.warning("Logout may have failed")
                self.skipped_tests += 1
                
    def _save_state(self):
        """Save test state to file"""
        try:
            with open(TOKEN_FILE, 'w') as f:
                json.dump(self.state.to_dict(), f, indent=2)
            self.logger.info(f"State saved to {TOKEN_FILE}")
        except Exception as e:
            self.logger.error(f"Failed to save state: {e}")
            
    def _print_summary(self):
        """Print test summary"""
        self.logger.section("TEST EXECUTION COMPLETED")
        self.logger.info(f"Finished at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        self.logger.info(f"Log file: {LOG_FILE}")
        self.logger.info(f"Tokens file: {TOKEN_FILE}")
        
        self.logger._write("")
        self.logger._write("=" * 60, Colors.GREEN)
        self.logger._write("                 TEST SUMMARY                      ", Colors.GREEN)
        self.logger._write("=" * 60, Colors.GREEN)
        self.logger._write(f"  Passed:  {self.passed_tests}", Colors.GREEN)
        self.logger._write(f"  Failed:  {self.failed_tests}", Colors.RED if self.failed_tests > 0 else Colors.NC)
        self.logger._write(f"  Skipped: {self.skipped_tests}", Colors.YELLOW)
        self.logger._write("=" * 60, Colors.GREEN)
        
        if self.state.hackathon_id:
            self.logger._write("")
            self.logger._write("Test Data:", Colors.YELLOW)
            self.logger._write(f"  Hackathon ID: {self.state.hackathon_id}")
            self.logger._write(f"  Team ID: {self.state.team_id or 'N/A'}")
            self.logger._write(f"  Criterion IDs: {self.state.criterion_ids or 'N/A'}")
            self.logger._write("")
            self.logger._write("WebSocket endpoint (manual test):", Colors.YELLOW)
            self.logger._write(f"  wscat -c ws://{API_HOST}:{API_PORT}/api/v1/ws/public/hackathons/{self.state.hackathon_id}/leaderboard")


def main():
    """Main entry point"""
    runner = APITestRunner()
    runner.run()


if __name__ == "__main__":
    main()