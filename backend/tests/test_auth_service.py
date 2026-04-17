# backend/tests/test_auth_service.py
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime, timedelta
from uuid import uuid4

from app.services.auth_service import AuthService
from app.models.user import User
from app.models.role import Role
from app.models.refresh_token import RefreshToken
from app.core.security import get_password_hash


class TestAuthenticateUser:
    """Tests for user authentication"""
    
    @pytest.mark.asyncio
    async def test_authenticate_valid_user(self, mock_db, test_admin_user):
        """Test authenticating valid user"""
        test_admin_user.password_hash = get_password_hash("Admin123!")
        
        mock_db.execute.return_value.scalar_one_or_none.return_value = test_admin_user
        
        service = AuthService(mock_db)
        user = await service.authenticate_user("admin_test", "Admin123!")
        
        assert user is not None
        assert user.login == "admin_test"
        mock_db.commit.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_authenticate_invalid_password(self, mock_db, test_admin_user):
        """Test authenticating with invalid password"""
        test_admin_user.password_hash = get_password_hash("CorrectPassword123!")
        
        mock_db.execute.return_value.scalar_one_or_none.return_value = test_admin_user
        
        service = AuthService(mock_db)
        user = await service.authenticate_user("admin_test", "WrongPassword!")
        
        assert user is None
        mock_db.commit.assert_not_called()
    
    @pytest.mark.asyncio
    async def test_authenticate_nonexistent_user(self, mock_db):
        """Test authenticating non-existent user"""
        mock_db.execute.return_value.scalar_one_or_none.return_value = None
        
        service = AuthService(mock_db)
        user = await service.authenticate_user("nonexistent", "password")
        
        assert user is None
    
    @pytest.mark.asyncio
    async def test_authenticate_inactive_user(self, mock_db, test_admin_user):
        """Test authenticating inactive user"""
        test_admin_user.is_active = False
        test_admin_user.password_hash = get_password_hash("Admin123!")
        
        mock_db.execute.return_value.scalar_one_or_none.return_value = test_admin_user
        
        service = AuthService(mock_db)
        user = await service.authenticate_user("admin_test", "Admin123!")
        
        assert user is None
        mock_db.commit.assert_not_called()


class TestRefreshTokenManagement:
    """Tests for refresh token management"""
    
    @pytest.mark.asyncio
    async def test_create_refresh_token(self, mock_db, test_admin_user):
        """Test creating refresh token"""
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()
        
        service = AuthService(mock_db)
        token = await service.create_refresh_token(test_admin_user.id)
        
        assert token is not None
        assert isinstance(token, str)
        assert len(token) > 30
        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_create_refresh_token_with_metadata(self, mock_db, test_admin_user):
        """Test creating refresh token with metadata"""
        service = AuthService(mock_db)
        token = await service.create_refresh_token(
            test_admin_user.id,
            user_agent="Mozilla/5.0",
            ip_address="192.168.1.1"
        )
        
        assert token is not None
        # Verify that add was called with RefreshToken containing metadata
        call_args = mock_db.add.call_args[0][0]
        assert isinstance(call_args, RefreshToken)
        assert call_args.user_agent == "Mozilla/5.0"
        assert str(call_args.ip_address) == "192.168.1.1"
    
    @pytest.mark.asyncio
    async def test_validate_valid_refresh_token(self, mock_db, test_admin_user):
        """Test validating valid refresh token"""
        mock_refresh_token = MagicMock(spec=RefreshToken)
        mock_refresh_token.user_id = test_admin_user.id
        mock_refresh_token.revoked_at = None
        mock_refresh_token.expires_at = datetime.utcnow() + timedelta(days=1)
        
        mock_db.execute.return_value.scalar_one_or_none.return_value = mock_refresh_token
        mock_db.execute.return_value.scalar_one_or_none.return_value = test_admin_user
        
        service = AuthService(mock_db)
        user = await service.validate_refresh_token("valid_token_string")
        
        assert user is not None
        assert user.id == test_admin_user.id
    
    @pytest.mark.asyncio
    async def test_validate_expired_refresh_token(self, mock_db, test_admin_user):
        """Test validating expired refresh token"""
        mock_refresh_token = MagicMock(spec=RefreshToken)
        mock_refresh_token.user_id = test_admin_user.id
        mock_refresh_token.revoked_at = None
        mock_refresh_token.expires_at = datetime.utcnow() - timedelta(days=1)
        
        mock_db.execute.return_value.scalar_one_or_none.return_value = mock_refresh_token
        
        service = AuthService(mock_db)
        user = await service.validate_refresh_token("expired_token")
        
        assert user is None
    
    @pytest.mark.asyncio
    async def test_validate_revoked_refresh_token(self, mock_db, test_admin_user):
        """Test validating revoked refresh token"""
        mock_refresh_token = MagicMock(spec=RefreshToken)
        mock_refresh_token.user_id = test_admin_user.id
        mock_refresh_token.revoked_at = datetime.utcnow()
        mock_refresh_token.expires_at = datetime.utcnow() + timedelta(days=1)
        
        mock_db.execute.return_value.scalar_one_or_none.return_value = mock_refresh_token
        
        service = AuthService(mock_db)
        user = await service.validate_refresh_token("revoked_token")
        
        assert user is None
    
    @pytest.mark.asyncio
    async def test_revoke_refresh_token(self, mock_db):
        """Test revoking refresh token"""
        mock_refresh_token = MagicMock(spec=RefreshToken)
        mock_refresh_token.revoked_at = None
        
        mock_db.execute.return_value.scalar_one_or_none.return_value = mock_refresh_token
        
        service = AuthService(mock_db)
        await service.revoke_refresh_token("token_to_revoke")
        
        assert mock_refresh_token.revoked_at is not None
        mock_db.commit.assert_called_once()


class TestUserInfo:
    """Tests for user info retrieval"""
    
    @pytest.mark.asyncio
    async def test_get_user_info(self, mock_db, test_admin_user, test_role):
        """Test getting user info"""
        test_admin_user.role_id = test_role.id
        mock_db.execute.return_value.scalar_one_or_none.return_value = test_role
        
        service = AuthService(mock_db)
        user_info = await service.get_user_info(test_admin_user)
        
        assert user_info.id == test_admin_user.id
        assert user_info.login == test_admin_user.login
        assert user_info.full_name == test_admin_user.full_name
        assert user_info.role == "admin"
        assert user_info.is_active is True
    
    @pytest.mark.asyncio
    async def test_get_user_info_without_role(self, mock_db, test_admin_user):
        """Test getting user info when role not found"""
        mock_db.execute.return_value.scalar_one_or_none.return_value = None
        
        service = AuthService(mock_db)
        user_info = await service.get_user_info(test_admin_user)
        
        assert user_info.role == "unknown"


class TestChangePassword:
    """Tests for password change functionality"""
    
    @pytest.mark.asyncio
    async def test_change_password_success(self, mock_db, test_admin_user):
        """Test successful password change"""
        old_password = "OldPass123!"
        new_password = "NewPass456!"
        
        test_admin_user.password_hash = get_password_hash(old_password)
        
        service = AuthService(mock_db)
        success = await service.change_password(test_admin_user, old_password, new_password)
        
        assert success is True
        mock_db.commit.assert_called_once()
        # Verify password was actually changed
        from app.core.security import verify_password
        assert verify_password(new_password, test_admin_user.password_hash) is True
    
    @pytest.mark.asyncio
    async def test_change_password_wrong_old_password(self, mock_db, test_admin_user):
        """Test password change with wrong old password"""
        test_admin_user.password_hash = get_password_hash("CorrectPass123!")
        
        service = AuthService(mock_db)
        success = await service.change_password(test_admin_user, "WrongPass!", "NewPass456!")
        
        assert success is False
        mock_db.commit.assert_not_called()


class TestTokenGeneration:
    """Tests for token generation"""
    
    @pytest.mark.asyncio
    async def test_generate_tokens(self, mock_db, test_admin_user):
        """Test generating access and refresh tokens"""
        service = AuthService(mock_db)
        access_token, refresh_token = await service.generate_tokens(test_admin_user)
        
        assert access_token is not None
        assert refresh_token is not None
        assert isinstance(access_token, str)
        assert isinstance(refresh_token, str)
        assert access_token != refresh_token