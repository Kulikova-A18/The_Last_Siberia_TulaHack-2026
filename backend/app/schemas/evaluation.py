# backend/app/schemas/evaluation.py
from pydantic import BaseModel, Field, validator
from uuid import UUID
from datetime import datetime
from typing import Optional, List
from decimal import Decimal

class EvaluationItemRequest(BaseModel):
    criterion_id: UUID
    raw_score: float = Field(..., ge=0)
    comment: Optional[str] = None

class EvaluationDraftRequest(BaseModel):
    items: List[EvaluationItemRequest] = []
    overall_comment: Optional[str] = None

class EvaluationSubmitRequest(BaseModel):
    items: List[EvaluationItemRequest]
    overall_comment: Optional[str] = None

    @validator('items')
    def validate_items_not_empty(cls, v):
        if not v:
            raise ValueError('At least one criterion must be evaluated')
        return v

class EvaluationItemResponse(BaseModel):
    id: UUID
    criterion_id: UUID
    criterion_title: str
    raw_score: float
    comment: Optional[str] = None
    max_score: float
    weight_percent: float

class EvaluationResponse(BaseModel):
    id: UUID
    status: str
    overall_comment: Optional[str] = None
    submitted_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    items: List[EvaluationItemResponse]

class MyEvaluationResponse(BaseModel):
    evaluation_id: UUID
    status: str
    team: dict
    criteria: List[dict]
    overall_comment: Optional[str] = None
    updated_at: datetime

class AssignedTeamResponse(BaseModel):
    team_id: UUID
    team_name: str
    project_title: str
    evaluation_status: str
    submitted_at: Optional[datetime] = None

class AssignedTeamListResponse(BaseModel):
    items: List[AssignedTeamResponse]
    page: int
    page_size: int
    total: int