# backend/app/schemas/role.py
from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import Optional

class RoleResponse(BaseModel):
    id: UUID
    code: str
    name: str
    created_at: datetime

class PermissionResponse(BaseModel):
    id: UUID
    code: str
    name: str
    description: Optional[str] = None
    created_at: datetime