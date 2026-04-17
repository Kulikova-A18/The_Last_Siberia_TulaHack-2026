# backend/tests/conftest.py
import pytest
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime, timedelta
from uuid import uuid4

from app.main import app
from app.core.config import settings
from app.core.security import get_password_hash, create_access_token


@pytest.fixture(scope="session")
def event_loop():
    """Create event loop for tests"""
    import asyncio
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture
def mock_db():
    """Create a mock database session"""
    db = AsyncMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()
    db.execute = AsyncMock()
    return db


@pytest.fixture
def client():
    """Create test client"""
    return TestClient(app)


@pytest.fixture
def test_admin_user():
    """Create a test admin user"""
    user = MagicMock()
    user.id = uuid4()
    user.login = "admin_test"
    user.full_name = "Test Admin"
    user.email = "admin@test.com"
    user.phone = "+79990000000"
    user.password_hash = get_password_hash("Admin123!")
    user.role_id = uuid4()
    user.team_id = None
    user.is_active = True
    user.last_login_at = None
    user.created_at = datetime.utcnow()
    user.updated_at = datetime.utcnow()
    return user


@pytest.fixture
def test_expert_user():
    """Create a test expert user"""
    user = MagicMock()
    user.id = uuid4()
    user.login = "expert_test"
    user.full_name = "Test Expert"
    user.email = "expert@test.com"
    user.phone = "+79990000001"
    user.password_hash = get_password_hash("Expert123!")
    user.role_id = uuid4()
    user.team_id = None
    user.is_active = True
    user.last_login_at = None
    user.created_at = datetime.utcnow()
    user.updated_at = datetime.utcnow()
    return user


@pytest.fixture
def test_team_user():
    """Create a test team user"""
    user = MagicMock()
    user.id = uuid4()
    user.login = "team_test"
    user.full_name = "Test Team"
    user.email = "team@test.com"
    user.phone = "+79990000002"
    user.password_hash = get_password_hash("Team123!")
    user.role_id = uuid4()
    user.team_id = uuid4()
    user.is_active = True
    user.last_login_at = None
    user.created_at = datetime.utcnow()
    user.updated_at = datetime.utcnow()
    return user


@pytest.fixture
def test_role():
    """Create a test role"""
    role = MagicMock()
    role.id = uuid4()
    role.code = "admin"
    role.name = "Administrator"
    return role


@pytest.fixture
def admin_access_token(test_admin_user):
    """Create admin access token"""
    return create_access_token(data={"sub": str(test_admin_user.id)})


@pytest.fixture
def expert_access_token(test_expert_user):
    """Create expert access token"""
    return create_access_token(data={"sub": str(test_expert_user.id)})


@pytest.fixture
def team_access_token(test_team_user):
    """Create team access token"""
    return create_access_token(data={"sub": str(test_team_user.id)})


@pytest.fixture
def mock_get_current_user(test_admin_user):
    """Mock get_current_user dependency"""
    with patch("app.dependencies.auth.get_current_user") as mock:
        mock.return_value = test_admin_user
        yield mock


@pytest.fixture
def mock_db_session(mock_db):
    """Mock database session dependency"""
    with patch("app.core.database.get_db") as mock:
        mock.return_value.__aenter__.return_value = mock_db
        yield mock_db