# backend/app/schemas/team.py
from pydantic import BaseModel, Field, EmailStr
from uuid import UUID
from datetime import datetime
from typing import Optional, List

class TeamMemberCreate(BaseModel):
    full_name: str = Field(..., max_length=200)
    email: Optional[EmailStr] = None
    phone: Optional[str] = Field(None, max_length=32)
    organization: Optional[str] = Field(None, max_length=200)
    is_captain: bool = False

class TeamMemberUpdate(BaseModel):
    full_name: Optional[str] = Field(None, max_length=200)
    email: Optional[EmailStr] = None
    phone: Optional[str] = Field(None, max_length=32)
    organization: Optional[str] = Field(None, max_length=200)
    is_captain: Optional[bool] = None

class TeamMemberResponse(BaseModel):
    id: UUID
    full_name: str
    email: Optional[str] = None
    phone: Optional[str] = None
    organization: Optional[str] = None
    is_captain: bool
    created_at: datetime

class TeamAccount(BaseModel):
    login: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=6)

class TeamCreate(BaseModel):
    name: str = Field(..., max_length=150)
    captain_name: str = Field(..., max_length=150)
    contact_email: Optional[EmailStr] = None
    contact_phone: Optional[str] = Field(None, max_length=32)
    project_title: str = Field(..., max_length=200)
    description: Optional[str] = None
    account: Optional[TeamAccount] = None
    members: Optional[List[TeamMemberCreate]] = None

class TeamUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=150)
    captain_name: Optional[str] = Field(None, max_length=150)
    contact_email: Optional[EmailStr] = None
    contact_phone: Optional[str] = Field(None, max_length=32)
    project_title: Optional[str] = Field(None, max_length=200)
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
    members_count: Optional[int] = None
    evaluation_status: Optional[str] = None
    final_score: Optional[float] = None
    place: Optional[int] = None
    created_at: datetime
    updated_at: datetime

class TeamListResponse(BaseModel):
    items: List[TeamResponse]
    page: int
    page_size: int
    total: int

class TeamDetailResponse(BaseModel):
    id: UUID
    name: str
    captain_name: str
    contact_email: Optional[str] = None
    contact_phone: Optional[str] = None
    project_title: str
    description: Optional[str] = None
    members: List[TeamMemberResponse]
    assigned_experts: List[dict]
    evaluation_status: str
    final_score: Optional[float] = None
    place: Optional[int] = None