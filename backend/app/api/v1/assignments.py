# backend/app/api/v1/assignments.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Optional
from uuid import UUID
from datetime import datetime, timezone

from app.core.database import get_db
from app.dependencies.auth import get_current_user, admin_required
from app.models.user import User
from app.models.team import Team
from app.models.hackathon import Hackathon
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


@router.post("/", response_model=AssignmentResponse, status_code=status.HTTP_201_CREATED)
async def create_assignment(
    hackathon_id: UUID,
    assignment_data: AssignmentCreate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Create assignment (admin only)"""
    hackathon_result = await db.execute(select(Hackathon).where(Hackathon.id == hackathon_id))
    if not hackathon_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Hackathon not found")
    
    expert_result = await db.execute(select(User).where(User.id == assignment_data.expert_user_id))
    if not expert_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Expert not found")
    
    team_result = await db.execute(
        select(Team).where(
            Team.id == assignment_data.team_id,
            Team.hackathon_id == hackathon_id
        )
    )
    if not team_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Team not found in this hackathon")
    
    existing = await db.execute(
        select(ExpertTeamAssignment).where(
            ExpertTeamAssignment.hackathon_id == hackathon_id,
            ExpertTeamAssignment.expert_user_id == assignment_data.expert_user_id,
            ExpertTeamAssignment.team_id == assignment_data.team_id
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Assignment already exists")
    
    new_assignment = ExpertTeamAssignment(
        hackathon_id=hackathon_id,
        expert_user_id=assignment_data.expert_user_id,
        team_id=assignment_data.team_id,
        assigned_at=datetime.now(timezone.utc)
    )
    
    db.add(new_assignment)
    await db.commit()
    await db.refresh(new_assignment)
    
    return AssignmentResponse(
        id=new_assignment.id,
        hackathon_id=new_assignment.hackathon_id,
        expert_user_id=new_assignment.expert_user_id,
        team_id=new_assignment.team_id,
        assigned_at=new_assignment.assigned_at,
        created_at=new_assignment.created_at
    )


@router.post("/bulk", response_model=list[AssignmentResponse], status_code=status.HTTP_201_CREATED)
async def bulk_create_assignments(
    hackathon_id: UUID,
    assignments_data: AssignmentBulkCreate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Bulk create assignments (admin only)"""
    hackathon_result = await db.execute(select(Hackathon).where(Hackathon.id == hackathon_id))
    if not hackathon_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Hackathon not found")
    
    created_assignments = []
    
    for assignment_item in assignments_data.assignments:
        existing = await db.execute(
            select(ExpertTeamAssignment).where(
                ExpertTeamAssignment.hackathon_id == hackathon_id,
                ExpertTeamAssignment.expert_user_id == assignment_item.expert_user_id,
                ExpertTeamAssignment.team_id == assignment_item.team_id
            )
        )
        if existing.scalar_one_or_none():
            continue
        
        new_assignment = ExpertTeamAssignment(
            hackathon_id=hackathon_id,
            expert_user_id=assignment_item.expert_user_id,
            team_id=assignment_item.team_id,
            assigned_at=datetime.now(timezone.utc)
        )
        db.add(new_assignment)
        created_assignments.append(new_assignment)
    
    await db.commit()
    
    for a in created_assignments:
        await db.refresh(a)
    
    return [AssignmentResponse(
        id=a.id,
        hackathon_id=a.hackathon_id,
        expert_user_id=a.expert_user_id,
        team_id=a.team_id,
        assigned_at=a.assigned_at,
        created_at=a.created_at
    ) for a in created_assignments]


@router.delete("/{assignment_id}")
async def delete_assignment(
    hackathon_id: UUID,
    assignment_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Delete assignment (admin only)"""
    result = await db.execute(
        select(ExpertTeamAssignment).where(
            ExpertTeamAssignment.id == assignment_id,
            ExpertTeamAssignment.hackathon_id == hackathon_id
        )
    )
    assignment = result.scalar_one_or_none()
    
    if not assignment:
        raise HTTPException(status_code=404, detail="Assignment not found")
    
    await db.delete(assignment)
    await db.commit()
    
    return {"message": "Assignment deleted successfully"}