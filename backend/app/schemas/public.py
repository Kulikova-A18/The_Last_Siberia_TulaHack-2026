# backend/app/schemas/public.py
from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import List, Optional

class PublicLeaderboardItem(BaseModel):
    place: int
    team_name: str
    final_score: float

class PublicLeaderboardResponse(BaseModel):
    published: bool
    items: List[PublicLeaderboardItem]
    updated_at: datetime

class PublicTimerResponse(BaseModel):
    hackathon_status: str
    current_phase: str
    next_deadline_title: Optional[str] = None
    next_deadline_at: Optional[datetime] = None
    seconds_remaining: Optional[int] = None

class PublicWinnersResponse(BaseModel):
    top_3: List[PublicLeaderboardItem]
    total_teams: int

class PublicHackathonResponse(BaseModel):
    id: UUID
    title: str
    description: Optional[str] = None
    start_at: datetime
    end_at: datetime
    status: str