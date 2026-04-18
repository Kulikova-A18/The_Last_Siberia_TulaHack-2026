# backend/app/api/v1/results.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from uuid import UUID
from datetime import datetime, timezone

from app.core.database import get_db
from app.dependencies.auth import get_current_user, admin_required
from app.models.user import User
from app.models.hackathon import Hackathon
from app.models.team import Team
from app.models.team_result import TeamResult
from app.schemas.result import LeaderboardResponse, TeamResultDetailResponse, WinnersResponse, LeaderboardItem

router = APIRouter(prefix="/hackathons/{hackathon_id}/results", tags=["Results"])


@router.get("/leaderboard", response_model=LeaderboardResponse)
async def get_leaderboard(
    hackathon_id: UUID,
    published_only: bool = False,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get leaderboard"""
    result = await db.execute(select(Hackathon).where(Hackathon.id == hackathon_id))
    hackathon = result.scalar_one_or_none()
    
    if not hackathon:
        raise HTTPException(status_code=404, detail="Hackathon not found")
    
    if published_only and not hackathon.results_published:
        return LeaderboardResponse(
            published=False,
            frozen=hackathon.results_frozen,
            items=[]
        )
    
    # Get team results
    results_query = (
        select(TeamResult, Team)
        .join(Team, (TeamResult.team_id == Team.id) & (TeamResult.hackathon_id == Team.hackathon_id))
        .where(TeamResult.hackathon_id == hackathon_id)
        .order_by(TeamResult.final_score.desc())
    )
    
    results_result = await db.execute(results_query)
    rows = results_result.all()
    
    items = []
    for idx, (tr, team) in enumerate(rows, 1):
        items.append(LeaderboardItem(
            place=tr.place or idx,
            team_id=team.id,
            team_name=team.name,
            final_score=float(tr.final_score),
            evaluated_by_count=tr.evaluated_by_count
        ))
    
    return LeaderboardResponse(
        published=hackathon.results_published,
        frozen=hackathon.results_frozen,
        items=items
    )


@router.get("/teams/{team_id}", response_model=TeamResultDetailResponse)
async def get_team_result(
    hackathon_id: UUID,
    team_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get detailed result for a team"""
    result = await db.execute(
        select(TeamResult).where(
            TeamResult.hackathon_id == hackathon_id,
            TeamResult.team_id == team_id
        )
    )
    team_result = result.scalar_one_or_none()
    
    if not team_result:
        return TeamResultDetailResponse(
            team_id=team_id,
            final_score=0,
            place=None,
            evaluated_by_count=0,
            criteria_breakdown=[]
        )
    
    # Get criteria breakdown
    from app.models.team_result import TeamResultItem
    from app.models.criterion import Criterion
    
    items_result = await db.execute(
        select(TeamResultItem, Criterion)
        .join(Criterion, TeamResultItem.criterion_id == Criterion.id)
        .where(TeamResultItem.team_result_id == team_result.id)
        .order_by(Criterion.sort_order)
    )
    rows = items_result.all()
    
    criteria_breakdown = []
    for item, criterion in rows:
        criteria_breakdown.append({
            "criterion_id": criterion.id,
            "title": criterion.title,
            "avg_raw_score": float(item.avg_raw_score),
            "avg_normalized_score": float(item.avg_normalized_score),
            "weighted_score": float(item.weighted_score),
            "weight_percent": float(criterion.weight_percent),
            "max_score": float(criterion.max_score)
        })
    
    return TeamResultDetailResponse(
        team_id=team_id,
        final_score=float(team_result.final_score),
        place=team_result.place,
        evaluated_by_count=team_result.evaluated_by_count,
        criteria_breakdown=criteria_breakdown
    )


@router.post("/recalculate")
async def recalculate_results(
    hackathon_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Recalculate all results (admin only)"""
    # TODO: Implement full recalculation logic
    return {"message": "Results recalculation started"}


@router.post("/publish")
async def publish_results(
    hackathon_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Publish results (admin only)"""
    result = await db.execute(select(Hackathon).where(Hackathon.id == hackathon_id))
    hackathon = result.scalar_one_or_none()
    
    if not hackathon:
        raise HTTPException(status_code=404, detail="Hackathon not found")
    
    hackathon.results_published = True
    hackathon.results_published_at = datetime.now(timezone.utc)
    hackathon.leaderboard_updated_at = datetime.now(timezone.utc)
    
    await db.commit()
    
    return {"message": "Results published successfully"}


@router.post("/unpublish")
async def unpublish_results(
    hackathon_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Unpublish results (admin only)"""
    result = await db.execute(select(Hackathon).where(Hackathon.id == hackathon_id))
    hackathon = result.scalar_one_or_none()
    
    if not hackathon:
        raise HTTPException(status_code=404, detail="Hackathon not found")
    
    hackathon.results_published = False
    
    await db.commit()
    
    return {"message": "Results unpublished successfully"}


@router.post("/freeze")
async def freeze_results(
    hackathon_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Freeze results (admin only)"""
    result = await db.execute(select(Hackathon).where(Hackathon.id == hackathon_id))
    hackathon = result.scalar_one_or_none()
    
    if not hackathon:
        raise HTTPException(status_code=404, detail="Hackathon not found")
    
    hackathon.results_frozen = True
    hackathon.results_frozen_at = datetime.now(timezone.utc)
    
    await db.commit()
    
    return {"message": "Results frozen successfully"}


@router.get("/winners", response_model=WinnersResponse)
async def get_winners(
    hackathon_id: UUID,
    top: int = Query(3, ge=1, le=10),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get winners"""
    result = await db.execute(select(Hackathon).where(Hackathon.id == hackathon_id))
    hackathon = result.scalar_one_or_none()
    
    if not hackathon:
        raise HTTPException(status_code=404, detail="Hackathon not found")
    
    if not hackathon.results_published:
        return WinnersResponse(items=[], total_teams=0)
    
    # Get top teams
    results_query = (
        select(TeamResult, Team)
        .join(Team, (TeamResult.team_id == Team.id) & (TeamResult.hackathon_id == Team.hackathon_id))
        .where(TeamResult.hackathon_id == hackathon_id)
        .order_by(TeamResult.final_score.desc())
        .limit(top)
    )
    
    results_result = await db.execute(results_query)
    rows = results_result.all()
    
    # Count total teams
    total_result = await db.execute(
        select(func.count()).select_from(Team).where(Team.hackathon_id == hackathon_id)
    )
    total_teams = total_result.scalar_one()
    
    items = []
    for idx, (tr, team) in enumerate(rows, 1):
        items.append({
            "place": idx,
            "team_id": team.id,
            "team_name": team.name,
            "final_score": float(tr.final_score)
        })
    
    return WinnersResponse(items=items, total_teams=total_teams)


@router.get("/export")
async def export_results(
    hackathon_id: UUID,
    format: str = Query("csv", regex="^(csv|xlsx)$"),
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Export results (admin only)"""
    # TODO: Implement export
    return {"message": f"Export in {format} format"}