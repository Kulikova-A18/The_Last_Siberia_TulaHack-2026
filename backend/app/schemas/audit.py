# backend/app/schemas/audit.py
from pydantic import BaseModel
from typing import Optional, Any, Dict
from uuid import UUID
from datetime import datetime


class AuditLogItem(BaseModel):
    """Single audit log entry"""
    id: int
    hackathon_id: Optional[UUID] = None
    actor_user_id: Optional[UUID] = None
    action: str
    entity_type: str
    entity_id: Optional[UUID] = None
    payload: Dict[str, Any] = {}
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    created_at: datetime
    
    class Config:
        from_attributes = True


class AuditLogResponse(BaseModel):
    """Single audit log response (alias for AuditLogItem)"""
    id: int
    hackathon_id: Optional[UUID] = None
    actor_user_id: Optional[UUID] = None
    action: str
    entity_type: str
    entity_id: Optional[UUID] = None
    payload: Dict[str, Any] = {}
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    created_at: datetime
    
    class Config:
        from_attributes = True


class AuditLogListResponse(BaseModel):
    """Paginated list of audit logs"""
    items: list[AuditLogItem]
    page: int
    page_size: int
    total: int