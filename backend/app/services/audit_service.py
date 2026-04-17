# backend/app/services/audit_service.py
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, desc
from uuid import UUID
from typing import Optional, List, Tuple, Dict, Any
from datetime import datetime

from app.models.audit_log import AuditLog
from app.models.user import User


class AuditService:
    """Service for managing audit logs"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def log_action(
        self,
        action: str,
        entity_type: str,
        entity_id: Optional[UUID] = None,
        actor_user_id: Optional[UUID] = None,
        hackathon_id: Optional[UUID] = None,
        payload: Dict[str, Any] = None,
        ip_address: str = None,
        user_agent: str = None
    ) -> AuditLog:
        """Log an action to audit log"""
        audit_log = AuditLog(
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            actor_user_id=actor_user_id,
            hackathon_id=hackathon_id,
            payload=payload or {},
            ip_address=ip_address,
            user_agent=user_agent
        )
        
        self.db.add(audit_log)
        await self.db.commit()
        await self.db.refresh(audit_log)
        
        return audit_log
    
    async def log_user_created(
        self,
        user_id: UUID,
        created_by: UUID,
        user_data: Dict[str, Any]
    ) -> AuditLog:
        """Log user creation"""
        return await self.log_action(
            action="user_created",
            entity_type="user",
            entity_id=user_id,
            actor_user_id=created_by,
            payload={"user_data": user_data}
        )
    
    async def log_evaluation_submitted(
        self,
        evaluation_id: UUID,
        team_id: UUID,
        expert_id: UUID,
        hackathon_id: UUID
    ) -> AuditLog:
        """Log evaluation submission"""
        return await self.log_action(
            action="evaluation_submitted",
            entity_type="evaluation",
            entity_id=evaluation_id,
            actor_user_id=expert_id,
            hackathon_id=hackathon_id,
            payload={"team_id": str(team_id)}
        )
    
    async def log_results_published(
        self,
        hackathon_id: UUID,
        published_by: UUID
    ) -> AuditLog:
        """Log results publication"""
        return await self.log_action(
            action="results_published",
            entity_type="hackathon",
            entity_id=hackathon_id,
            actor_user_id=published_by,
            hackathon_id=hackathon_id
        )
    
    async def log_results_frozen(
        self,
        hackathon_id: UUID,
        frozen_by: UUID
    ) -> AuditLog:
        """Log results freezing"""
        return await self.log_action(
            action="results_frozen",
            entity_type="hackathon",
            entity_id=hackathon_id,
            actor_user_id=frozen_by,
            hackathon_id=hackathon_id
        )
    
    async def get_audit_logs(
        self,
        hackathon_id: Optional[UUID] = None,
        entity_type: Optional[str] = None,
        user_id: Optional[UUID] = None,
        action: Optional[str] = None,
        page: int = 1,
        page_size: int = 50
    ) -> Tuple[List[AuditLog], int]:
        """Get audit logs with filters and pagination"""
        query = select(AuditLog)
        count_query = select(func.count()).select_from(AuditLog)
        
        if hackathon_id:
            query = query.where(AuditLog.hackathon_id == hackathon_id)
            count_query = count_query.where(AuditLog.hackathon_id == hackathon_id)
        
        if entity_type:
            query = query.where(AuditLog.entity_type == entity_type)
            count_query = count_query.where(AuditLog.entity_type == entity_type)
        
        if user_id:
            query = query.where(AuditLog.actor_user_id == user_id)
            count_query = count_query.where(AuditLog.actor_user_id == user_id)
        
        if action:
            query = query.where(AuditLog.action == action)
            count_query = count_query.where(AuditLog.action == action)
        
        # Get total count
        total_result = await self.db.execute(count_query)
        total = total_result.scalar_one()
        
        # Get paginated results
        query = query.order_by(desc(AuditLog.created_at))
        query = query.offset((page - 1) * page_size).limit(page_size)
        
        result = await self.db.execute(query)
        logs = result.scalars().all()
        
        return list(logs), total
    
    async def get_audit_logs_with_actors(
        self,
        hackathon_id: Optional[UUID] = None,
        page: int = 1,
        page_size: int = 50
    ) -> Tuple[List[Dict[str, Any]], int]:
        """Get audit logs with actor information"""
        logs, total = await self.get_audit_logs(
            hackathon_id=hackathon_id,
            page=page,
            page_size=page_size
        )
        
        # Get actor names
        actor_ids = list(set(log.actor_user_id for log in logs if log.actor_user_id))
        actors = {}
        
        if actor_ids:
            from sqlalchemy import select
            result = await self.db.execute(
                select(User.id, User.full_name).where(User.id.in_(actor_ids))
            )
            for user_id, full_name in result.all():
                actors[str(user_id)] = full_name
        
        result_logs = []
        for log in logs:
            result_logs.append({
                "id": log.id,
                "action": log.action,
                "entity_type": log.entity_type,
                "entity_id": log.entity_id,
                "payload": log.payload,
                "created_at": log.created_at,
                "performed_by": {
                    "id": log.actor_user_id,
                    "full_name": actors.get(str(log.actor_user_id), "Unknown")
                } if log.actor_user_id else None
            })
        
        return result_logs, total