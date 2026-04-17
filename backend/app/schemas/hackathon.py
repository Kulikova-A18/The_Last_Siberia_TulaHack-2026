# backend/app/schemas/hackathon.py
from pydantic import BaseModel, Field
from uuid import UUID
from datetime import datetime
from typing import Optional

class HackathonCreate(BaseModel):
    title: str = Field(..., max_length=200)
    description: Optional[str] = None
    start_at: datetime
    end_at: datetime

class HackathonUpdate(BaseModel):
    title: Optional[str] = Field(None, max_length=200)
    description: Optional[str] = None
    start_at: Optional[datetime] = None
    end_at: Optional[datetime] = None
    status: Optional[str] = None

class HackathonResponse(BaseModel):
    id: UUID
    title: str
    description: Optional[str] = None
    start_at: datetime
    end_at: datetime
    status: str
    results_published: bool
    results_frozen: bool
    created_at: datetime
    updated_at: datetime