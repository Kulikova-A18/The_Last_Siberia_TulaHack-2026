# backend/app/schemas/deadline.py
from pydantic import BaseModel, Field
from uuid import UUID
from datetime import datetime
from typing import Optional

class DeadlineCreate(BaseModel):
    title: str = Field(..., max_length=150)
    description: Optional[str] = None
    deadline_at: datetime
    notify_before_minutes: int = Field(0, ge=0)
    kind: str = "custom"

class DeadlineUpdate(BaseModel):
    title: Optional[str] = Field(None, max_length=150)
    description: Optional[str] = None
    deadline_at: Optional[datetime] = None
    notify_before_minutes: Optional[int] = Field(None, ge=0)
    kind: Optional[str] = None

class DeadlineResponse(BaseModel):
    id: UUID
    hackathon_id: UUID
    kind: str
    title: str
    description: Optional[str] = None
    deadline_at: datetime
    notify_before_minutes: int
    created_at: datetime
    updated_at: datetime

class NextDeadlineResponse(BaseModel):
    id: UUID
    title: str
    deadline_at: datetime

class TimerResponse(BaseModel):
    server_time: datetime
    hackathon_status: str
    current_phase: str
    next_deadline: Optional[NextDeadlineResponse] = None
    seconds_remaining: Optional[int] = None