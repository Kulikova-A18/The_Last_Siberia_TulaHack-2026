"""
Logger for API tests with colored console output
"""
import json
import sys
from datetime import datetime
from typing import Optional, Dict, Any
from config import Colors


class TestLogger:
    """Logger for test execution"""
    
    def __init__(self, log_file: str):
        self.log_file = log_file
        self.file_handle = open(log_file, 'w', encoding='utf-8')
        
    def close(self):
        """Close log file"""
        if self.file_handle:
            self.file_handle.close()
            
    def _write(self, text: str, color: Optional[str] = None):
        """Write to console and file"""
        if color:
            print(f"{color}{text}{Colors.NC}")
        else:
            print(text)
        self.file_handle.write(text + '\n')
        self.file_handle.flush()
        
    def section(self, title: str):
        """Log a section header"""
        self._write("")
        self._write("=" * 60, Colors.BLUE)
        self._write(f">>> {title}", Colors.BLUE)
        self._write("=" * 60, Colors.BLUE)
        
    def info(self, message: str):
        """Log info message"""
        self._write(f"[INFO] {message}")
        
    def success(self, message: str):
        """Log success message"""
        self._write(f"[SUCCESS] {message}", Colors.GREEN)
        
    def warning(self, message: str):
        """Log warning message"""
        self._write(f"[WARNING] {message}", Colors.YELLOW)
        
    def error(self, message: str):
        """Log error message"""
        self._write(f"[ERROR] {message}", Colors.RED)
        
    def log_request(self, method: str, url: str, data: Optional[Dict] = None):
        """Log API request"""
        self._write(f"> Request: {method} {url}", Colors.YELLOW)
        if data:
            self._write(f"> Body: {json.dumps(data, indent=2, ensure_ascii=False)}", Colors.YELLOW)
            
    def log_response(self, status_code: int, body: Any):
        """Log API response"""
        color = Colors.GREEN if 200 <= status_code < 300 else Colors.RED
        self._write(f"< Response (HTTP {status_code}):", color)
        if isinstance(body, dict):
            self._write(json.dumps(body, indent=2, ensure_ascii=False))
        else:
            self._write(str(body))
            
    def log_error(self, message: str):
        """Log error message"""
        self._write(f"[ERROR] {message}", Colors.RED)
        
    def log_json(self, data: Any):
        """Log JSON data"""
        self._write(json.dumps(data, indent=2, ensure_ascii=False))
        
    def divider(self):
        """Log a divider line"""
        self._write("-" * 40)