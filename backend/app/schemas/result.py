# backend/app/schemas/result.py
from pydantic import BaseModel
from typing import Optional, List
from uuid import UUID
from datetime import datetime


class LeaderboardItem(BaseModel):
    place: int
    team_id: UUID
    team_name: str
    project_title: Optional[str] = None
    final_score: float
    evaluated_by_count: int = 0
    status: Optional[str] = None  # Принимает строку
    
    class Config:
        from_attributes = True


class LeaderboardResponse(BaseModel):
    published: bool
    frozen: bool
    items: List[LeaderboardItem] = []
    updated_at: Optional[datetime] = None

class CriteriaBreakdownItem(BaseModel):
    criterion_id: UUID
    title: str
    avg_raw_score: float
    avg_normalized_score: float
    weighted_score: float
    weight_percent: float
    max_score: float


class TeamResultDetailResponse(BaseModel):
    team_id: UUID
    final_score: float
    place: Optional[int] = None
    evaluated_by_count: int = 0
    criteria_breakdown: List[dict] = []


class WinnerItem(BaseModel):
    place: int
    team_id: UUID
    team_name: str
    final_score: float


class WinnersResponse(BaseModel):
    items: List[dict] = []
    total_teams: int = 0