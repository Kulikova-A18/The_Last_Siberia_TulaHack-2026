# backend/app/schemas/user.py
from pydantic import BaseModel, Field, EmailStr
from uuid import UUID
from datetime import datetime
from typing import Optional, List

class UserCreate(BaseModel):
    login: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=6)
    full_name: str = Field(..., max_length=200)
    email: Optional[EmailStr] = None
    phone: Optional[str] = Field(None, max_length=32)
    role_code: str
    team_id: Optional[UUID] = None
    is_active: bool = True

class UserUpdate(BaseModel):
    full_name: Optional[str] = Field(None, max_length=200)
    email: Optional[EmailStr] = None
    phone: Optional[str] = Field(None, max_length=32)
    is_active: Optional[bool] = None

class UserResponse(BaseModel):
    id: UUID
    login: str
    full_name: str
    role_code: str
    email: Optional[str] = None
    phone: Optional[str] = None
    team_id: Optional[UUID] = None
    is_active: bool
    last_login_at: Optional[datetime] = None
    created_at: datetime

class ResetPasswordRequest(BaseModel):
    new_password: str = Field(..., min_length=6)

class UserListResponse(BaseModel):
    items: List[UserResponse]
    page: int
    page_size: int
    total: int