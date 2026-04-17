# backend/app/schemas/auth.py
from pydantic import BaseModel, Field
from typing import Optional
from uuid import UUID

class LoginRequest(BaseModel):
    login: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=6)

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: "UserInfo"

class UserInfo(BaseModel):
    id: UUID
    login: str
    full_name: str
    role: str
    team_id: Optional[UUID] = None
    is_active: bool

class RefreshTokenRequest(BaseModel):
    refresh_token: str

class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str = Field(..., min_length=6)