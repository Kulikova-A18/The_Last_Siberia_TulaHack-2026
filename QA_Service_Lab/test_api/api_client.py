"""
API Client for testing Hackathon Platform
"""
import json
import requests
from typing import Optional, Dict, Any, Tuple
from dataclasses import dataclass
from colorama import init, Fore, Style

# Initialize colorama for Windows compatibility
init(autoreset=True)

@dataclass
class APIResponse:
    """API Response wrapper"""
    status_code: int
    body: Dict[str, Any]
    raw_body: str
    success: bool
    
    def get(self, key: str, default=None):
        """Get value from response body"""
        return self.body.get(key, default) if isinstance(self.body, dict) else default
    
    def __bool__(self):
        return self.success


class APIClient:
    """HTTP client for API testing"""
    
    def __init__(self, base_url: str, logger):
        self.base_url = base_url.rstrip('/')
        self.logger = logger
        self.session = requests.Session()
        self.session.headers.update({"Content-Type": "application/json"})
        
    def set_token(self, token: str):
        """Set bearer token for authentication"""
        if token:
            self.session.headers.update({"Authorization": f"Bearer {token}"})
        else:
            self.session.headers.pop("Authorization", None)
            
    def clear_token(self):
        """Remove authentication token"""
        self.session.headers.pop("Authorization", None)
        
    def call(self, method: str, endpoint: str, 
             data: Optional[Dict] = None, 
             token: Optional[str] = None) -> APIResponse:
        """
        Make an API call and return response
        
        Args:
            method: HTTP method (GET, POST, PUT, PATCH, DELETE)
            endpoint: API endpoint (e.g., "/auth/login")
            data: Request body data
            token: Optional bearer token
            
        Returns:
            APIResponse object with status_code, body, and success flag
        """
        url = f"{self.base_url}{endpoint}"
        
        # Set token if provided
        original_headers = self.session.headers.copy()
        if token:
            self.set_token(token)
            
        # Log request
        self.logger.log_request(method, url, data)
        
        try:
            # Make request
            response = self.session.request(
                method=method,
                url=url,
                json=data,
                timeout=30
            )
            
            # Parse response
            try:
                body = response.json()
                raw_body = json.dumps(body, indent=2, ensure_ascii=False)
            except json.JSONDecodeError:
                body = {"error": response.text}
                raw_body = response.text
                
            # Log response
            self.logger.log_response(response.status_code, body)
            
            # Restore original headers
            self.session.headers.update(original_headers)
            
            return APIResponse(
                status_code=response.status_code,
                body=body,
                raw_body=raw_body,
                success=200 <= response.status_code < 300
            )
            
        except requests.exceptions.RequestException as e:
            self.logger.log_error(f"Request failed: {str(e)}")
            self.session.headers.update(original_headers)
            return APIResponse(
                status_code=0,
                body={"error": str(e)},
                raw_body=str(e),
                success=False
            )
            
    def get(self, endpoint: str, token: Optional[str] = None) -> APIResponse:
        """GET request"""
        return self.call("GET", endpoint, token=token)
        
    def post(self, endpoint: str, data: Optional[Dict] = None, 
             token: Optional[str] = None) -> APIResponse:
        """POST request"""
        return self.call("POST", endpoint, data=data, token=token)
        
    def put(self, endpoint: str, data: Optional[Dict] = None, 
            token: Optional[str] = None) -> APIResponse:
        """PUT request"""
        return self.call("PUT", endpoint, data=data, token=token)
        
    def patch(self, endpoint: str, data: Optional[Dict] = None, 
              token: Optional[str] = None) -> APIResponse:
        """PATCH request"""
        return self.call("PATCH", endpoint, data=data, token=token)
        
    def delete(self, endpoint: str, token: Optional[str] = None) -> APIResponse:
        """DELETE request"""
        return self.call("DELETE", endpoint, token=token)