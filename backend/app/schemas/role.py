# backend/app/schemas/role.py
from pydantic import BaseModel
from uuid import UUID
from datetime import datetime

class RoleResponse(BaseModel):
    id: UUID
    code: str
    name: str
    created_at: datetime

class PermissionResponse(BaseModel):
    id: UUID
    code: str
    name: str
    description: str | None = None
    created_at: datetime

class RolePermissionResponse(BaseModel):
    role_id: UUID
    permission_id: UUID