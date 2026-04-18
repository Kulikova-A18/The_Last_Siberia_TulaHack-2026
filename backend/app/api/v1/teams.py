# backend/app/api/v1/teams.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import Optional
from uuid import UUID

from app.core.database import get_db
from app.dependencies.auth import get_current_user, admin_required
from app.models.user import User
from app.models.team import Team
from app.models.team_member import TeamMember
from app.models.team_result import TeamResult
from app.schemas.team import (
    TeamCreate, TeamUpdate, TeamResponse, TeamListResponse, 
    TeamDetailResponse, TeamMemberCreate, TeamMemberUpdate, TeamMemberResponse
)

router = APIRouter(prefix="/hackathons/{hackathon_id}/teams", tags=["Teams"])

@router.get("/", response_model=TeamListResponse)
async def get_teams(
    hackathon_id: UUID,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: Optional[str] = None,
    status: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get list of teams"""
    query = select(Team).where(Team.hackathon_id == hackathon_id)
    count_query = select(func.count()).select_from(Team).where(Team.hackathon_id == hackathon_id)
    
    if search:
        search_filter = (Team.name.ilike(f"%{search}%")) | (Team.project_title.ilike(f"%{search}%"))
        query = query.where(search_filter)
        count_query = count_query.where(search_filter)
    
    # Get total count
    total_result = await db.execute(count_query)
    total = total_result.scalar_one()
    
    # Get paginated results
    query = query.order_by(Team.created_at.desc())
    query = query.offset((page - 1) * page_size).limit(page_size)
    
    result = await db.execute(query)
    teams = result.scalars().all()
    
    items = []
    for team in teams:
        # Get evaluation status and score
        result_result = await db.execute(
            select(TeamResult).where(TeamResult.team_id == team.id)
        )
        team_result = result_result.scalar_one_or_none()
        
        # Count members
        members_count = await db.execute(
            select(func.count()).select_from(TeamMember).where(TeamMember.team_id == team.id)
        )
        
        items.append(TeamResponse(
            id=team.id,
            hackathon_id=team.hackathon_id,
            name=team.name,
            captain_name=team.captain_name,
            contact_email=team.contact_email,
            contact_phone=team.contact_phone,
            project_title=team.project_title,
            description=team.description,
            members_count=members_count.scalar_one(),
            evaluation_status=team_result.status if team_result else None,
            final_score=float(team_result.final_score) if team_result else None,
            place=team_result.place if team_result else None,
            created_at=team.created_at,
            updated_at=team.updated_at
        ))
    
    return TeamListResponse(
        items=items,
        page=page,
        page_size=page_size,
        total=total
    )

@router.post("/", response_model=TeamResponse)
async def create_team(
    hackathon_id: UUID,
    team_data: TeamCreate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Create a new team (admin only)"""
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.get("/{team_id}", response_model=TeamDetailResponse)
async def get_team(
    hackathon_id: UUID,
    team_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get team by ID"""
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.patch("/{team_id}", response_model=TeamResponse)
async def update_team(
    hackathon_id: UUID,
    team_id: UUID,
    team_data: TeamUpdate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Update team (admin only)"""
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.delete("/{team_id}")
async def delete_team(
    hackathon_id: UUID,
    team_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Delete team (admin only)"""
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.post("/{team_id}/members", response_model=TeamMemberResponse)
async def add_member(
    hackathon_id: UUID,
    team_id: UUID,
    member_data: TeamMemberCreate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Add member to team (admin only)"""
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.patch("/{team_id}/members/{member_id}", response_model=TeamMemberResponse)
async def update_member(
    hackathon_id: UUID,
    team_id: UUID,
    member_id: UUID,
    member_data: TeamMemberUpdate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Update team member (admin only)"""
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.delete("/{team_id}/members/{member_id}")
async def delete_member(
    hackathon_id: UUID,
    team_id: UUID,
    member_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Delete team member (admin only)"""
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )