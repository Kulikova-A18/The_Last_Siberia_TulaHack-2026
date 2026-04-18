# backend/app/api/v1/audit_logs.py
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from uuid import UUID
from typing import Optional

from app.core.database import get_db
from app.dependencies.auth import admin_required
from app.models.user import User
from app.models.audit_log import AuditLog
from app.schemas.audit import AuditLogListResponse, AuditLogItem

router = APIRouter(prefix="/hackathons/{hackathon_id}/audit-logs", tags=["Audit"])


@router.get("/", response_model=AuditLogListResponse)
async def get_audit_logs(
    hackathon_id: UUID,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    entity_type: Optional[str] = None,
    user_id: Optional[UUID] = None,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Get audit logs (admin only)"""
    query = select(AuditLog).where(AuditLog.hackathon_id == hackathon_id)
    count_query = select(func.count()).select_from(AuditLog).where(AuditLog.hackathon_id == hackathon_id)
    
    if entity_type:
        query = query.where(AuditLog.entity_type == entity_type)
        count_query = count_query.where(AuditLog.entity_type == entity_type)
    
    if user_id:
        query = query.where(AuditLog.actor_user_id == user_id)
        count_query = count_query.where(AuditLog.actor_user_id == user_id)
    
    total_result = await db.execute(count_query)
    total = total_result.scalar_one()
    
    query = query.order_by(AuditLog.created_at.desc())
    query = query.offset((page - 1) * page_size).limit(page_size)
    
    result = await db.execute(query)
    logs = result.scalars().all()
    
    items = []
    for log in logs:
        items.append(AuditLogItem(
            id=log.id,
            hackathon_id=log.hackathon_id,
            actor_user_id=log.actor_user_id,
            action=log.action,
            entity_type=log.entity_type,
            entity_id=log.entity_id,
            payload=log.payload,
            ip_address=str(log.ip_address) if log.ip_address else None,
            user_agent=log.user_agent,
            created_at=log.created_at
        ))
    
    return AuditLogListResponse(
        items=items,
        page=page,
        page_size=page_size,
        total=total
    )