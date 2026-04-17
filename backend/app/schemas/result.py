# backend/app/schemas/result.py
from pydantic import BaseModel
from uuid import UUID
from typing import Optional, List
from datetime import datetime

class LeaderboardItem(BaseModel):
    place: int
    team_id: UUID
    team_name: str
    project_title: str
    final_score: float
    evaluated_by_count: int
    status: str

class LeaderboardResponse(BaseModel):
    published: bool
    frozen: bool
    items: List[LeaderboardItem]
    updated_at: Optional[datetime] = None

class CriterionBreakdown(BaseModel):
    criterion_id: UUID
    title: str
    weight_percent: float
    max_score: float
    avg_raw_score: float
    weighted_score: float

class TeamResultDetailResponse(BaseModel):
    team_id: UUID
    team_name: str
    place: Optional[int] = None
    final_score: float
    criteria_breakdown: List[CriterionBreakdown]
    experts_count: int
    status: str
    published: bool

class WinnersItem(BaseModel):
    place: int
    team_id: UUID
    team_name: str
    final_score: float
    project_title: str

class WinnersResponse(BaseModel):
    items: List[WinnersItem]
    total_teams: int