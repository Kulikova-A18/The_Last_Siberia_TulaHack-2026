# backend/tests/test_audit_service.py
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from uuid import uuid4
from datetime import datetime

from app.services.audit_service import AuditService
from app.models.audit_log import AuditLog


class TestAuditLogCreation:
    """Tests for audit log creation"""
    
    @pytest.mark.asyncio
    async def test_log_action(self):
        """Test logging an action"""
        mock_db = AsyncMock()
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()
        mock_db.refresh = AsyncMock()
        
        service = AuditService(mock_db)
        
        audit_log = await service.log_action(
            action="user_created",
            entity_type="user",
            entity_id=uuid4(),
            actor_user_id=uuid4(),
            hackathon_id=uuid4(),
            payload={"username": "testuser"},
            ip_address="192.168.1.1",
            user_agent="Mozilla/5.0"
        )
        
        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_log_action_minimal(self):
        """Test logging action with minimal fields"""
        mock_db = AsyncMock()
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()
        mock_db.refresh = AsyncMock()
        
        service = AuditService(mock_db)
        
        audit_log = await service.log_action(
            action="login",
            entity_type="user",
            entity_id=uuid4(),
            actor_user_id=uuid4()
        )
        
        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_log_user_created(self):
        """Test logging user creation"""
        mock_db = AsyncMock()
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()
        mock_db.refresh = AsyncMock()
        
        service = AuditService(mock_db)
        
        await service.log_user_created(
            user_id=uuid4(),
            created_by=uuid4(),
            user_data={"login": "newuser", "role": "expert"}
        )
        
        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_log_evaluation_submitted(self):
        """Test logging evaluation submission"""
        mock_db = AsyncMock()
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()
        mock_db.refresh = AsyncMock()
        
        service = AuditService(mock_db)
        
        await service.log_evaluation_submitted(
            evaluation_id=uuid4(),
            team_id=uuid4(),
            expert_id=uuid4(),
            hackathon_id=uuid4()
        )
        
        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_log_results_published(self):
        """Test logging results publication"""
        mock_db = AsyncMock()
        mock_db.add = MagicMock()
        mock_db.commit = AsyncMock()
        mock_db.refresh = AsyncMock()
        
        service = AuditService(mock_db)
        
        await service.log_results_published(
            hackathon_id=uuid4(),
            published_by=uuid4()
        )
        
        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()


class TestAuditLogRetrieval:
    """Tests for audit log retrieval"""
    
    @pytest.mark.asyncio
    async def test_get_audit_logs(self):
        """Test getting audit logs"""
        mock_db = AsyncMock()
        
        mock_log = MagicMock(spec=AuditLog)
        mock_log.id = 1
        mock_log.action = "test_action"
        mock_log.entity_type = "user"
        
        mock_result = AsyncMock()
        mock_result.scalars.return_value.all.return_value = [mock_log]
        mock_result.scalar_one.return_value = 1
        mock_db.execute.return_value = mock_result
        
        service = AuditService(mock_db)
        logs, total = await service.get_audit_logs(page=1, page_size=10)
        
        assert len(logs) == 1
        assert total == 1
    
    @pytest.mark.asyncio
    async def test_get_audit_logs_empty(self):
        """Test getting audit logs when none exist"""
        mock_db = AsyncMock()
        
        mock_result = AsyncMock()
        mock_result.scalars.return_value.all.return_value = []
        mock_result.scalar_one.return_value = 0
        mock_db.execute.return_value = mock_result
        
        service = AuditService(mock_db)
        logs, total = await service.get_audit_logs(page=1, page_size=10)
        
        assert logs == []
        assert total == 0
    
    @pytest.mark.asyncio
    async def test_get_audit_logs_with_filters(self):
        """Test getting audit logs with filters"""
        mock_db = AsyncMock()
        
        mock_result = AsyncMock()
        mock_result.scalars.return_value.all.return_value = []
        mock_result.scalar_one.return_value = 0
        mock_db.execute.return_value = mock_result
        
        service = AuditService(mock_db)
        
        await service.get_audit_logs(
            hackathon_id=uuid4(),
            entity_type="evaluation",
            user_id=uuid4(),
            action="submitted",
            page=1,
            page_size=20
        )
        
        mock_db.execute.assert_called()