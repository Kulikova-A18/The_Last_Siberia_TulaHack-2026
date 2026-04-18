# backend/app/schemas/team.py
from pydantic import BaseModel
from typing import Optional, List
from uuid import UUID
from datetime import datetime


class TeamMemberCreate(BaseModel):
    full_name: str
    email: Optional[str] = None
    phone: Optional[str] = None
    organization: Optional[str] = None
    is_captain: bool = False


class TeamMemberUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    organization: Optional[str] = None
    is_captain: Optional[bool] = None


class TeamMemberResponse(BaseModel):
    id: UUID
    team_id: UUID
    full_name: str
    email: Optional[str] = None
    phone: Optional[str] = None
    organization: Optional[str] = None
    is_captain: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class TeamCreate(BaseModel):
    name: str
    captain_name: str
    contact_email: Optional[str] = None
    contact_phone: Optional[str] = None
    project_title: str
    description: Optional[str] = None


class TeamUpdate(BaseModel):
    name: Optional[str] = None
    captain_name: Optional[str] = None
    contact_email: Optional[str] = None
    contact_phone: Optional[str] = None
    project_title: Optional[str] = None
    description: Optional[str] = None


class TeamResponse(BaseModel):
    id: UUID
    hackathon_id: UUID
    name: str
    captain_name: str
    contact_email: Optional[str] = None
    contact_phone: Optional[str] = None
    project_title: str
    description: Optional[str] = None
    members_count: int = 0
    evaluation_status: Optional[str] = None
    final_score: Optional[float] = None
    place: Optional[int] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class AssignedExpertInfo(BaseModel):
    expert_id: UUID
    expert_name: str
    evaluation_status: Optional[str] = None
    evaluation_id: Optional[UUID] = None


class TeamDetailResponse(BaseModel):
    id: UUID
    hackathon_id: UUID
    name: str
    captain_name: str
    contact_email: Optional[str] = None
    contact_phone: Optional[str] = None
    project_title: str
    description: Optional[str] = None
    members: List[TeamMemberResponse] = []
    assigned_experts: Optional[List[AssignedExpertInfo]] = []  # Сделано опциональным
    evaluation_status: Optional[str] = None  # Может быть None
    final_score: Optional[float] = None
    place: Optional[int] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class TeamListResponse(BaseModel):
    items: List[TeamResponse]
    page: int
    page_size: int
    total: int