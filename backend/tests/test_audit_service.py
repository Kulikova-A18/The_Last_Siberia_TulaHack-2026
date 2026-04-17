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
    async def test_log_action(self, mock_db):
        """Test logging an action"""
        service = AuditService(mock_db)
        
        await service.log_action(
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
        
        added_log = mock_db.add.call_args[0][0]
        assert isinstance(added_log, AuditLog)
        assert added_log.action == "user_created"
        assert added_log.entity_type == "user"
        assert added_log.payload == {"username": "testuser"}
    
    @pytest.mark.asyncio
    async def test_log_action_minimal(self, mock_db):
        """Test logging action with minimal fields"""
        service = AuditService(mock_db)
        
        await service.log_action(
            action="login",
            entity_type="user",
            entity_id=uuid4(),
            actor_user_id=uuid4()
        )
        
        added_log = mock_db.add.call_args[0][0]
        assert added_log.hackathon_id is None
        assert added_log.payload == {}
        assert added_log.ip_address is None
    
    @pytest.mark.asyncio
    async def test_log_user_created(self, mock_db):
        """Test logging user creation"""
        service = AuditService(mock_db)
        
        await service.log_user_created(
            user_id=uuid4(),
            created_by=uuid4(),
            user_data={"login": "newuser", "role": "expert"}
        )
        
        added_log = mock_db.add.call_args[0][0]
        assert added_log.action == "user_created"
        assert added_log.entity_type == "user"
    
    @pytest.mark.asyncio
    async def test_log_evaluation_submitted(self, mock_db):
        """Test logging evaluation submission"""
        service = AuditService(mock_db)
        evaluation_id = uuid4()
        team_id = uuid4()
        expert_id = uuid4()
        hackathon_id = uuid4()
        
        await service.log_evaluation_submitted(
            evaluation_id=evaluation_id,
            team_id=team_id,
            expert_id=expert_id,
            hackathon_id=hackathon_id
        )
        
        added_log = mock_db.add.call_args[0][0]
        assert added_log.action == "evaluation_submitted"
        assert added_log.entity_type == "evaluation"
        assert added_log.entity_id == evaluation_id
        assert added_log.payload == {"team_id": str(team_id)}
    
    @pytest.mark.asyncio
    async def test_log_results_published(self, mock_db):
        """Test logging results publication"""
        service = AuditService(mock_db)
        hackathon_id = uuid4()
        published_by = uuid4()
        
        await service.log_results_published(
            hackathon_id=hackathon_id,
            published_by=published_by
        )
        
        added_log = mock_db.add.call_args[0][0]
        assert added_log.action == "results_published"
        assert added_log.entity_type == "hackathon"
        assert added_log.entity_id == hackathon_id


class TestAuditLogRetrieval:
    """Tests for audit log retrieval"""
    
    @pytest.mark.asyncio
    async def test_get_audit_logs(self, mock_db):
        """Test getting audit logs"""
        mock_logs = [
            MagicMock(spec=AuditLog),
            MagicMock(spec=AuditLog)
        ]
        
        mock_result = AsyncMock()
        mock_result.scalars.return_value.all.return_value = mock_logs
        mock_db.execute.return_value = mock_result
        
        service = AuditService(mock_db)
        logs, total = await service.get_audit_logs(
            hackathon_id=uuid4(),
            page=1,
            page_size=10
        )
        
        assert len(logs) == 2
        assert total == 2
    
    @pytest.mark.asyncio
    async def test_get_audit_logs_with_filters(self, mock_db):
        """Test getting audit logs with filters"""
        service = AuditService(mock_db)
        hackathon_id = uuid4()
        entity_type = "evaluation"
        user_id = uuid4()
        
        await service.get_audit_logs(
            hackathon_id=hackathon_id,
            entity_type=entity_type,
            user_id=user_id,
            page=1,
            page_size=20
        )
        
        # Verify that execute was called with query containing filters
        mock_db.execute.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_get_audit_logs_empty(self, mock_db):
        """Test getting audit logs when none exist"""
        mock_result = AsyncMock()
        mock_result.scalars.return_value.all.return_value = []
        mock_db.execute.return_value = mock_result
        
        service = AuditService(mock_db)
        logs, total = await service.get_audit_logs(page=1, page_size=10)
        
        assert logs == []
        assert total == 0