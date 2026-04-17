# backend/app/api/v1/evaluations.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
from uuid import UUID

from app.core.database import get_db
from app.dependencies.auth import get_current_user, expert_required, admin_required
from app.models.user import User
from app.schemas.evaluation import (
    EvaluationDraftRequest, EvaluationSubmitRequest, EvaluationResponse,
    MyEvaluationResponse, AssignedTeamListResponse
)

router = APIRouter(prefix="/hackathons/{hackathon_id}", tags=["Evaluations"])

@router.get("/my/assigned-teams", response_model=AssignedTeamListResponse)
async def get_my_assigned_teams(
    hackathon_id: UUID,
    status: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(expert_required),
    db: AsyncSession = Depends(get_db)
):
    """Get teams assigned to current expert"""
    # TODO: Implement assigned teams list
    return AssignedTeamListResponse(
        items=[],
        page=page,
        page_size=page_size,
        total=0
    )

@router.get("/teams/{team_id}/my-evaluation", response_model=MyEvaluationResponse)
async def get_my_evaluation(
    hackathon_id: UUID,
    team_id: UUID,
    current_user: User = Depends(expert_required),
    db: AsyncSession = Depends(get_db)
):
    """Get evaluation form for current expert"""
    # TODO: Implement evaluation retrieval
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.put("/teams/{team_id}/my-evaluation/draft", response_model=dict)
async def save_evaluation_draft(
    hackathon_id: UUID,
    team_id: UUID,
    draft_data: EvaluationDraftRequest,
    current_user: User = Depends(expert_required),
    db: AsyncSession = Depends(get_db)
):
    """Save evaluation draft"""
    # TODO: Implement draft saving
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.post("/teams/{team_id}/my-evaluation/submit", response_model=dict)
async def submit_evaluation(
    hackathon_id: UUID,
    team_id: UUID,
    submit_data: EvaluationSubmitRequest,
    current_user: User = Depends(expert_required),
    db: AsyncSession = Depends(get_db)
):
    """Submit final evaluation"""
    # TODO: Implement evaluation submission
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )