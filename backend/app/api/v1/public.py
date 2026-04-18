# backend/app/api/v1/public.py (полный исправленный файл)
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from uuid import UUID
from datetime import datetime, timezone

from app.core.database import get_db
from app.models.hackathon import Hackathon, HackathonStatus
from app.models.team_result import TeamResult
from app.models.team import Team
from app.models.deadline import Deadline
from app.schemas.public import (
    PublicLeaderboardResponse, PublicTimerResponse, 
    PublicWinnersResponse, PublicHackathonResponse, PublicLeaderboardItem
)

router = APIRouter(prefix="/public", tags=["Public"])


@router.get("/hackathons/active", response_model=PublicHackathonResponse)
async def get_active_public_hackathon(
    db: AsyncSession = Depends(get_db)
):
    """Get active hackathon for public view"""
    result = await db.execute(
        select(Hackathon)
        .where(Hackathon.status == HackathonStatus.ACTIVE)
        .order_by(Hackathon.created_at.desc())
        .limit(1)
    )
    hackathon = result.scalar_one_or_none()
    
    if not hackathon:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No active hackathon found"
        )
    
    return PublicHackathonResponse(
        id=hackathon.id,
        title=hackathon.title,
        description=hackathon.description,
        start_at=hackathon.start_at,
        end_at=hackathon.end_at,
        status=hackathon.status.value
    )


@router.get("/hackathons/{hackathon_id}/leaderboard", response_model=PublicLeaderboardResponse)
async def get_public_leaderboard(
    hackathon_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """Get public leaderboard"""
    result = await db.execute(select(Hackathon).where(Hackathon.id == hackathon_id))
    hackathon = result.scalar_one_or_none()
    
    if not hackathon:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Hackathon not found")
    
    items = []
    if hackathon.results_published:
        result = await db.execute(
            select(TeamResult, Team)
            .join(Team, (TeamResult.team_id == Team.id) & (TeamResult.hackathon_id == Team.hackathon_id))
            .where(TeamResult.hackathon_id == hackathon_id)
            .order_by(TeamResult.final_score.desc())
        )
        rows = result.all()
        
        for tr, team in rows:
            items.append(PublicLeaderboardItem(
                place=tr.place or 0,
                team_name=team.name,
                final_score=float(tr.final_score)
            ))
    
    return PublicLeaderboardResponse(
        published=hackathon.results_published,
        items=items,
        updated_at=hackathon.leaderboard_updated_at or hackathon.updated_at
    )


@router.get("/hackathons/{hackathon_id}/timer", response_model=PublicTimerResponse)
async def get_public_timer(
    hackathon_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """Get public timer"""
    result = await db.execute(select(Hackathon).where(Hackathon.id == hackathon_id))
    hackathon = result.scalar_one_or_none()
    
    if not hackathon:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Hackathon not found")
    
    # ИСПРАВЛЕНИЕ: использовать timezone-aware datetime и naive datetime для БД
    now_aware = datetime.now(timezone.utc)
    now_naive = now_aware.replace(tzinfo=None)  # Для сравнения с БД (TIMESTAMP WITHOUT TIME ZONE)
    
    result = await db.execute(
        select(Deadline)
        .where(Deadline.hackathon_id == hackathon_id, Deadline.deadline_at > now_naive)
        .order_by(Deadline.deadline_at)
        .limit(1)
    )
    next_deadline = result.scalar_one_or_none()
    
    current_phase = "active"
    seconds_remaining = None
    next_deadline_title = None
    next_deadline_at = None
    
    if hackathon.status.value == "active":
        # Использовать naive datetime для сравнения с полями БД
        if hackathon.end_at.replace(tzinfo=None) < now_naive:
            current_phase = "finished"
        elif hackathon.start_at.replace(tzinfo=None) > now_naive:
            current_phase = "not_started"
        else:
            current_phase = "active"
    
    if next_deadline:
        next_deadline_title = next_deadline.title
        next_deadline_at = next_deadline.deadline_at
        # Преобразовать naive datetime из БД в aware для вычисления разницы
        deadline_aware = next_deadline.deadline_at.replace(tzinfo=timezone.utc)
        seconds_remaining = int((deadline_aware - now_aware).total_seconds())
    
    return PublicTimerResponse(
        hackathon_status=hackathon.status.value,
        current_phase=current_phase,
        next_deadline_title=next_deadline_title,
        next_deadline_at=next_deadline_at,
        seconds_remaining=seconds_remaining
    )


@router.get("/hackathons/{hackathon_id}/winners", response_model=PublicWinnersResponse)
async def get_public_winners(
    hackathon_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """Get public winners"""
    result = await db.execute(select(Hackathon).where(Hackathon.id == hackathon_id))
    hackathon = result.scalar_one_or_none()
    
    if not hackathon:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Hackathon not found")
    
    if not hackathon.results_published:
        return PublicWinnersResponse(top_3=[], total_teams=0)
    
    result = await db.execute(
        select(TeamResult, Team)
        .join(Team, (TeamResult.team_id == Team.id) & (TeamResult.hackathon_id == Team.hackathon_id))
        .where(TeamResult.hackathon_id == hackathon_id)
        .order_by(TeamResult.final_score.desc())
        .limit(3)
    )
    rows = result.all()
    
    # Count total teams
    total_result = await db.execute(
        select(func.count()).select_from(Team).where(Team.hackathon_id == hackathon_id)
    )
    total_teams = total_result.scalar_one()
    
    top_3 = []
    for tr, team in rows:
        top_3.append(PublicLeaderboardItem(
            place=tr.place or 0,
            team_name=team.name,
            final_score=float(tr.final_score)
        ))
    
    return PublicWinnersResponse(top_3=top_3, total_teams=total_teams)