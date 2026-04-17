# backend/app/schemas/audit.py
from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import Optional, Dict, Any

class AuditLogResponse(BaseModel):
    id: int
    action: str
    entity_type: str
    entity_id: Optional[UUID] = None
    payload: Dict[str, Any]
    performed_by: Optional[Dict[str, Any]] = None
    created_at: datetime

class AuditLogListResponse(BaseModel):
    items: List[AuditLogResponse]
    page: int
    page_size: int
    total: int

class AuditLogPayload(BaseModel):
    team_id: Optional[UUID] = None
    user_id: Optional[UUID] = None
    changes: Optional[Dict[str, Any]] = None