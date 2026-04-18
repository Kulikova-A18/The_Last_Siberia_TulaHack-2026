# backend/app/api/v1/teams.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import Optional
from uuid import UUID
from app.models.team_result import TeamResult
from app.schemas.team import AssignedExpertInfo

from app.core.database import get_db
from app.dependencies.auth import get_current_user, admin_required
from app.models.user import User
from app.models.team import Team
from app.models.team_member import TeamMember
from app.models.team_result import TeamResult
from app.models.hackathon import Hackathon
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
    # Verify hackathon exists
    hackathon_result = await db.execute(select(Hackathon).where(Hackathon.id == hackathon_id))
    if not hackathon_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Hackathon not found")
    
    query = select(Team).where(Team.hackathon_id == hackathon_id)
    count_query = select(func.count()).select_from(Team).where(Team.hackathon_id == hackathon_id)
    
    if search:
        search_filter = (Team.name.ilike(f"%{search}%")) | (Team.project_title.ilike(f"%{search}%"))
        query = query.where(search_filter)
        count_query = count_query.where(search_filter)
    
    total_result = await db.execute(count_query)
    total = total_result.scalar_one()
    
    query = query.order_by(Team.created_at.desc())
    query = query.offset((page - 1) * page_size).limit(page_size)
    
    result = await db.execute(query)
    teams = result.scalars().all()
    
    items = []
    for team in teams:
        result_result = await db.execute(
            select(TeamResult).where(TeamResult.team_id == team.id)
        )
        team_result = result_result.scalar_one_or_none()
        
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
            evaluation_status=team_result.status.value if team_result else None,
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


@router.post("/", response_model=TeamResponse, status_code=status.HTTP_201_CREATED)
async def create_team(
    hackathon_id: UUID,
    team_data: TeamCreate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Create a new team (admin only)"""
    # Verify hackathon exists
    hackathon_result = await db.execute(select(Hackathon).where(Hackathon.id == hackathon_id))
    if not hackathon_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Hackathon not found")
    
    # Check if team name exists in this hackathon
    existing = await db.execute(
        select(Team).where(
            Team.hackathon_id == hackathon_id,
            Team.name == team_data.name
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Team name already exists in this hackathon")
    
    new_team = Team(
        hackathon_id=hackathon_id,
        name=team_data.name,
        captain_name=team_data.captain_name,
        contact_email=team_data.contact_email,
        contact_phone=team_data.contact_phone,
        project_title=team_data.project_title,
        description=team_data.description
    )
    
    db.add(new_team)
    await db.commit()
    await db.refresh(new_team)
    
    return TeamResponse(
        id=new_team.id,
        hackathon_id=new_team.hackathon_id,
        name=new_team.name,
        captain_name=new_team.captain_name,
        contact_email=new_team.contact_email,
        contact_phone=new_team.contact_phone,
        project_title=new_team.project_title,
        description=new_team.description,
        members_count=0,
        evaluation_status=None,
        final_score=None,
        place=None,
        created_at=new_team.created_at,
        updated_at=new_team.updated_at
    )

@router.get("/{team_id}", response_model=TeamDetailResponse)
async def get_team(
    hackathon_id: UUID,
    team_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get team by ID"""
    result = await db.execute(
        select(Team).where(Team.id == team_id, Team.hackathon_id == hackathon_id)
    )
    team = result.scalar_one_or_none()
    
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")
    
    # Get members
    members_result = await db.execute(
        select(TeamMember).where(TeamMember.team_id == team_id)
    )
    members = members_result.scalars().all()
    
    # Get team result
    result_result = await db.execute(
        select(TeamResult).where(
            TeamResult.team_id == team_id,
            TeamResult.hackathon_id == hackathon_id
        )
    )
    team_result = result_result.scalar_one_or_none()
    
    # Get assigned experts
    from app.models.expert_team_assignment import ExpertTeamAssignment
    from app.models.evaluation import Evaluation
    
    experts_query = (
        select(ExpertTeamAssignment, User, Evaluation)
        .join(User, ExpertTeamAssignment.expert_user_id == User.id)
        .outerjoin(
            Evaluation,
            (Evaluation.hackathon_id == ExpertTeamAssignment.hackathon_id) &
            (Evaluation.expert_user_id == ExpertTeamAssignment.expert_user_id) &
            (Evaluation.team_id == ExpertTeamAssignment.team_id)
        )
        .where(
            ExpertTeamAssignment.hackathon_id == hackathon_id,
            ExpertTeamAssignment.team_id == team_id
        )
    )
    
    experts_result = await db.execute(experts_query)
    experts_rows = experts_result.all()
    
    assigned_experts = []
    for assignment, expert, evaluation in experts_rows:
        assigned_experts.append({
            "expert_id": expert.id,
            "expert_name": expert.full_name,
            "evaluation_status": evaluation.status.value if evaluation else "not_started",
            "evaluation_id": evaluation.id if evaluation else None
        })
    
    member_responses = [
        TeamMemberResponse(
            id=m.id,
            team_id=m.team_id,
            full_name=m.full_name,
            email=m.email,
            phone=m.phone,
            organization=m.organization,
            is_captain=m.is_captain,
            created_at=m.created_at,
            updated_at=m.updated_at
        ) for m in members
    ]
    
    return TeamDetailResponse(
        id=team.id,
        hackathon_id=team.hackathon_id,
        name=team.name,
        captain_name=team.captain_name,
        contact_email=team.contact_email,
        contact_phone=team.contact_phone,
        project_title=team.project_title,
        description=team.description,
        members=member_responses,
        assigned_experts=assigned_experts if assigned_experts else [],
        evaluation_status=team_result.status.value if team_result else None,
        final_score=float(team_result.final_score) if team_result else None,
        place=team_result.place if team_result else None,
        created_at=team.created_at,
        updated_at=team.updated_at
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
    result = await db.execute(
        select(Team).where(Team.id == team_id, Team.hackathon_id == hackathon_id)
    )
    team = result.scalar_one_or_none()
    
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")
    
    update_data = team_data.model_dump(exclude_unset=True)
    
    # Check name uniqueness if changing
    if "name" in update_data and update_data["name"] != team.name:
        existing = await db.execute(
            select(Team).where(
                Team.hackathon_id == hackathon_id,
                Team.name == update_data["name"],
                Team.id != team_id
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Team name already exists")
    
    for field, value in update_data.items():
        if value is not None:
            setattr(team, field, value)
    
    await db.commit()
    await db.refresh(team)
    
    members_count = await db.execute(
        select(func.count()).select_from(TeamMember).where(TeamMember.team_id == team.id)
    )
    
    return TeamResponse(
        id=team.id,
        hackathon_id=team.hackathon_id,
        name=team.name,
        captain_name=team.captain_name,
        contact_email=team.contact_email,
        contact_phone=team.contact_phone,
        project_title=team.project_title,
        description=team.description,
        members_count=members_count.scalar_one(),
        evaluation_status=None,
        final_score=None,
        place=None,
        created_at=team.created_at,
        updated_at=team.updated_at
    )


@router.delete("/{team_id}")
async def delete_team(
    hackathon_id: UUID,
    team_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Delete team (admin only)"""
    result = await db.execute(
        select(Team).where(Team.id == team_id, Team.hackathon_id == hackathon_id)
    )
    team = result.scalar_one_or_none()
    
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")
    
    await db.delete(team)
    await db.commit()
    
    return {"message": "Team deleted successfully"}


@router.post("/{team_id}/members", response_model=TeamMemberResponse, status_code=status.HTTP_201_CREATED)
async def add_member(
    hackathon_id: UUID,
    team_id: UUID,
    member_data: TeamMemberCreate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Add member to team (admin only)"""
    # Verify team exists
    team_result = await db.execute(
        select(Team).where(Team.id == team_id, Team.hackathon_id == hackathon_id)
    )
    team = team_result.scalar_one_or_none()
    
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")
    
    # If setting as captain, unset existing captain
    if member_data.is_captain:
        await db.execute(
            select(TeamMember).where(
                TeamMember.team_id == team_id,
                TeamMember.is_captain == True
            )
        )
        existing_captain = (await db.execute(
            select(TeamMember).where(
                TeamMember.team_id == team_id,
                TeamMember.is_captain == True
            )
        )).scalar_one_or_none()
        if existing_captain:
            existing_captain.is_captain = False
    
    new_member = TeamMember(
        team_id=team_id,
        full_name=member_data.full_name,
        email=member_data.email,
        phone=member_data.phone,
        organization=member_data.organization,
        is_captain=member_data.is_captain
    )
    
    db.add(new_member)
    await db.commit()
    await db.refresh(new_member)
    
    # Update team captain_name if this is captain
    if member_data.is_captain:
        team.captain_name = member_data.full_name
        await db.commit()
    
    return TeamMemberResponse(
        id=new_member.id,
        team_id=new_member.team_id,
        full_name=new_member.full_name,
        email=new_member.email,
        phone=new_member.phone,
        organization=new_member.organization,
        is_captain=new_member.is_captain,
        created_at=new_member.created_at,
        updated_at=new_member.updated_at
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
    result = await db.execute(
        select(TeamMember).where(TeamMember.id == member_id, TeamMember.team_id == team_id)
    )
    member = result.scalar_one_or_none()
    
    if not member:
        raise HTTPException(status_code=404, detail="Team member not found")
    
    # Get team for captain name update
    team_result = await db.execute(select(Team).where(Team.id == team_id))
    team = team_result.scalar_one()
    
    # Handle captain changes
    if member_data.is_captain and not member.is_captain:
        # Unset existing captain
        existing_captain = (await db.execute(
            select(TeamMember).where(
                TeamMember.team_id == team_id,
                TeamMember.is_captain == True
            )
        )).scalar_one_or_none()
        if existing_captain:
            existing_captain.is_captain = False
        team.captain_name = member.full_name
    
    update_data = member_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        if value is not None:
            setattr(member, field, value)
    
    # Update team captain name if full_name changed for captain
    if member.is_captain and "full_name" in update_data:
        team.captain_name = member.full_name
    
    await db.commit()
    await db.refresh(member)
    
    return TeamMemberResponse(
        id=member.id,
        team_id=member.team_id,
        full_name=member.full_name,
        email=member.email,
        phone=member.phone,
        organization=member.organization,
        is_captain=member.is_captain,
        created_at=member.created_at,
        updated_at=member.updated_at
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
    result = await db.execute(
        select(TeamMember).where(TeamMember.id == member_id, TeamMember.team_id == team_id)
    )
    member = result.scalar_one_or_none()
    
    if not member:
        raise HTTPException(status_code=404, detail="Team member not found")
    
    await db.delete(member)
    await db.commit()
    
    return {"message": "Team member deleted successfully"}
