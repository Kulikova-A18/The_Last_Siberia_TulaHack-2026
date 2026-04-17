# backend/tests/test_security.py
import pytest
from app.core.security import verify_password, get_password_hash


class TestPasswordHashing:
    """Tests for password hashing functions"""
    
    def test_hash_password(self):
        """Test password hashing"""
        password = "SecurePassword123!"
        hashed = get_password_hash(password)
        
        assert hashed != password
        assert len(hashed) > 20
    
    def test_verify_correct_password(self):
        """Test verifying correct password"""
        password = "SecurePassword123!"
        hashed = get_password_hash(password)
        
        assert verify_password(password, hashed) is True
    
    def test_verify_incorrect_password(self):
        """Test verifying incorrect password"""
        password = "SecurePassword123!"
        wrong_password = "WrongPassword123!"
        hashed = get_password_hash(password)
        
        assert verify_password(wrong_password, hashed) is False