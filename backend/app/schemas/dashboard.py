# backend/app/schemas/dashboard.py
from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import List, Optional

class LeaderboardTopItem(BaseModel):
    place: int
    team_id: UUID
    team_name: str
    final_score: float

class ExpertsProgressItem(BaseModel):
    expert_id: UUID
    expert_name: str
    submitted: int
    total_assigned: int

class NextDeadlineItem(BaseModel):
    id: UUID
    title: str
    deadline_at: datetime

class AdminDashboardResponse(BaseModel):
    teams_total: int
    experts_total: int
    criteria_total: int
    evaluations_submitted: int
    evaluations_draft: int
    evaluations_total_expected: int
    leaderboard_top: List[LeaderboardTopItem]
    experts_progress: List[ExpertsProgressItem]
    next_deadline: Optional[NextDeadlineItem] = None

class ExpertDashboardResponse(BaseModel):
    assigned_teams_count: int
    evaluated_count: int
    remaining_count: int
    next_deadline: Optional[NextDeadlineItem] = None

class TeamDashboardResponse(BaseModel):
    team_name: str
    project_title: str
    evaluation_status: str
    final_score: Optional[float] = None
    place: Optional[int] = None
    next_deadline: Optional[NextDeadlineItem] = None