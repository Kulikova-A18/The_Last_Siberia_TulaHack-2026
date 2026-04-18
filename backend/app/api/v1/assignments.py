# backend/app/api/v1/assignments.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Optional
from uuid import UUID

from app.core.database import get_db
from app.dependencies.auth import get_current_user, admin_required
from app.models.user import User
from app.models.expert_team_assignment import ExpertTeamAssignment
from app.schemas.assignment import AssignmentCreate, AssignmentBulkCreate, AssignmentResponse

router = APIRouter(prefix="/hackathons/{hackathon_id}/assignments", tags=["Assignments"])


@router.get("/", response_model=list[AssignmentResponse])
async def get_assignments(
    hackathon_id: UUID,
    expert_id: Optional[UUID] = None,
    team_id: Optional[UUID] = None,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Get assignments (admin only)"""
    query = select(ExpertTeamAssignment).where(ExpertTeamAssignment.hackathon_id == hackathon_id)
    
    if expert_id:
        query = query.where(ExpertTeamAssignment.expert_user_id == expert_id)
    if team_id:
        query = query.where(ExpertTeamAssignment.team_id == team_id)
    
    result = await db.execute(query)
    assignments = result.scalars().all()
    
    return [AssignmentResponse(
        id=a.id,
        hackathon_id=a.hackathon_id,
        expert_user_id=a.expert_user_id,
        team_id=a.team_id,
        assigned_at=a.assigned_at,
        created_at=a.created_at
    ) for a in assignments]

@router.post("/", response_model=AssignmentResponse)
async def create_assignment(
    hackathon_id: UUID,
    assignment_data: AssignmentCreate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Create assignment (admin only)"""
    # TODO: Implement assignment creation
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.post("/bulk", response_model=list[AssignmentResponse])
async def bulk_create_assignments(
    hackathon_id: UUID,
    assignments_data: AssignmentBulkCreate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Bulk create assignments (admin only)"""
    # TODO: Implement bulk assignment creation
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.delete("/{assignment_id}")
async def delete_assignment(
    hackathon_id: UUID,
    assignment_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Delete assignment (admin only)"""
    # TODO: Implement assignment deletion
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )