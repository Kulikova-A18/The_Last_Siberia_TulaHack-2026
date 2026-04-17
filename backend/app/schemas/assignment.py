# backend/app/schemas/assignment.py
from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import List

class AssignmentCreate(BaseModel):
    expert_user_id: UUID
    team_id: UUID

class AssignmentBulkItem(BaseModel):
    expert_user_id: UUID
    team_id: UUID

class AssignmentBulkCreate(BaseModel):
    items: List[AssignmentBulkItem]

class AssignmentResponse(BaseModel):
    id: UUID
    hackathon_id: UUID
    expert_user_id: UUID
    team_id: UUID
    assigned_at: datetime
    created_at: datetime