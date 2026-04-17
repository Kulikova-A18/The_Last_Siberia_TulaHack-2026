# backend/tests/test_security.py
import pytest
from datetime import datetime, timedelta
from jose import jwt
from unittest.mock import patch, MagicMock

from app.core.security import (
    verify_password,
    get_password_hash,
    create_access_token,
    create_refresh_token,
    decode_token
)
from app.core.config import settings


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
    
    def test_verify_empty_password(self):
        """Test verifying empty password"""
        hashed = get_password_hash("test123")
        assert verify_password("", hashed) is False
    
    def test_different_passwords_produce_different_hashes(self):
        """Test that different passwords produce different hashes"""
        hash1 = get_password_hash("password1")
        hash2 = get_password_hash("password2")
        
        assert hash1 != hash2


class TestTokenCreation:
    """Tests for JWT token creation"""
    
    def test_create_access_token(self):
        """Test creating access token"""
        data = {"sub": "user123", "role": "admin"}
        token = create_access_token(data)
        
        assert token is not None
        assert isinstance(token, str)
        assert len(token) > 20
    
    def test_create_access_token_with_expiry(self):
        """Test creating access token with custom expiry"""
        data = {"sub": "user123"}
        expires_delta = timedelta(minutes=30)
        token = create_access_token(data, expires_delta)
        
        decoded = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        assert decoded["sub"] == "user123"
        assert decoded["type"] == "access"
    
    def test_create_refresh_token(self):
        """Test creating refresh token"""
        data = {"sub": "user123"}
        token = create_refresh_token(data)
        
        decoded = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        assert decoded["sub"] == "user123"
        assert decoded["type"] == "refresh"
    
    def test_access_token_has_expiry(self):
        """Test that access token has expiry claim"""
        data = {"sub": "user123"}
        token = create_access_token(data)
        
        decoded = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        assert "exp" in decoded
        assert isinstance(decoded["exp"], (int, float))
    
    def test_refresh_token_has_longer_expiry(self):
        """Test that refresh token has longer expiry than access token"""
        data = {"sub": "user123"}
        access_token = create_access_token(data)
        refresh_token = create_refresh_token(data)
        
        access_decoded = jwt.decode(access_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        refresh_decoded = jwt.decode(refresh_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        
        assert refresh_decoded["exp"] > access_decoded["exp"]


class TestTokenDecoding:
    """Tests for JWT token decoding"""
    
    def test_decode_valid_token(self):
        """Test decoding valid token"""
        data = {"sub": "user123", "email": "test@example.com"}
        token = create_access_token(data)
        
        decoded = decode_token(token)
        assert decoded["sub"] == "user123"
        assert decoded["email"] == "test@example.com"
    
    def test_decode_invalid_token(self):
        """Test decoding invalid token"""
        invalid_token = "invalid.token.here"
        decoded = decode_token(invalid_token)
        
        assert decoded == {}
    
    def test_decode_expired_token(self):
        """Test decoding expired token"""
        data = {"sub": "user123"}
        expires_delta = timedelta(seconds=-1)
        token = create_access_token(data, expires_delta)
        
        decoded = decode_token(token)
        assert decoded == {}
    
    def test_decode_malformed_token(self):
        """Test decoding malformed token"""
        malformed_token = "not-a-valid-jwt-token"
        decoded = decode_token(malformed_token)
        
        assert decoded == {}
    
    def test_decode_token_with_wrong_secret(self):
        """Test decoding token with wrong secret"""
        data = {"sub": "user123"}
        token = create_access_token(data)
        
        # Temporarily change secret key
        original_secret = settings.SECRET_KEY
        settings.SECRET_KEY = "different_secret_key"
        
        try:
            decoded = decode_token(token)
            assert decoded == {}
        finally:
            settings.SECRET_KEY = original_secret


class TestTokenTypeValidation:
    """Tests for token type validation"""
    
    def test_access_token_has_correct_type(self):
        """Test that access token has correct type claim"""
        token = create_access_token({"sub": "user123"})
        decoded = decode_token(token)
        assert decoded.get("type") == "access"
    
    def test_refresh_token_has_correct_type(self):
        """Test that refresh token has correct type claim"""
        token = create_refresh_token({"sub": "user123"})
        decoded = decode_token(token)
        assert decoded.get("type") == "refresh"
    
    def test_access_token_cannot_be_used_as_refresh(self):
        """Test that access token cannot be used as refresh token"""
        access_token = create_access_token({"sub": "user123"})
        refresh_token = create_refresh_token({"sub": "user123"})
        
        assert access_token != refresh_token
        decoded_access = decode_token(access_token)
        decoded_refresh = decode_token(refresh_token)
        
        assert decoded_access.get("type") == "access"
        assert decoded_refresh.get("type") == "refresh"