# backend/app/api/v1/deadlines.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from uuid import UUID
from datetime import datetime, timezone

from app.core.database import get_db
from app.dependencies.auth import get_current_user, admin_required
from app.models.user import User
from app.models.hackathon import Hackathon
from app.models.deadline import Deadline
from app.schemas.deadline import DeadlineCreate, DeadlineUpdate, DeadlineResponse, TimerResponse

router = APIRouter(prefix="/hackathons/{hackathon_id}/deadlines", tags=["Deadlines"])


@router.get("/", response_model=list[DeadlineResponse])
async def get_deadlines(
    hackathon_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get all deadlines for hackathon"""
    result = await db.execute(
        select(Deadline)
        .where(Deadline.hackathon_id == hackathon_id)
        .order_by(Deadline.deadline_at)
    )
    deadlines = result.scalars().all()
    return [DeadlineResponse.model_validate(d) for d in deadlines]


@router.post("/", response_model=DeadlineResponse)
async def create_deadline(
    hackathon_id: UUID,
    deadline_data: DeadlineCreate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Create a new deadline (admin only)"""
    # Verify hackathon exists
    result = await db.execute(select(Hackathon).where(Hackathon.id == hackathon_id))
    hackathon = result.scalar_one_or_none()
    if not hackathon:
        raise HTTPException(status_code=404, detail="Hackathon not found")
    
    new_deadline = Deadline(
        hackathon_id=hackathon_id,
        kind=deadline_data.kind,
        title=deadline_data.title,
        description=deadline_data.description,
        deadline_at=deadline_data.deadline_at,
        notify_before_minutes=deadline_data.notify_before_minutes
    )
    
    db.add(new_deadline)
    await db.commit()
    await db.refresh(new_deadline)
    
    return DeadlineResponse.model_validate(new_deadline)


@router.get("/{deadline_id}", response_model=DeadlineResponse)
async def get_deadline(
    hackathon_id: UUID,
    deadline_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get deadline by ID"""
    result = await db.execute(
        select(Deadline)
        .where(Deadline.id == deadline_id, Deadline.hackathon_id == hackathon_id)
    )
    deadline = result.scalar_one_or_none()
    
    if not deadline:
        raise HTTPException(status_code=404, detail="Deadline not found")
    
    return DeadlineResponse.model_validate(deadline)


@router.patch("/{deadline_id}", response_model=DeadlineResponse)
async def update_deadline(
    hackathon_id: UUID,
    deadline_id: UUID,
    deadline_data: DeadlineUpdate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Update deadline (admin only)"""
    result = await db.execute(
        select(Deadline)
        .where(Deadline.id == deadline_id, Deadline.hackathon_id == hackathon_id)
    )
    deadline = result.scalar_one_or_none()
    
    if not deadline:
        raise HTTPException(status_code=404, detail="Deadline not found")
    
    update_data = deadline_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(deadline, field, value)
    
    await db.commit()
    await db.refresh(deadline)
    
    return DeadlineResponse.model_validate(deadline)


@router.delete("/{deadline_id}")
async def delete_deadline(
    hackathon_id: UUID,
    deadline_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Delete deadline (admin only)"""
    result = await db.execute(
        select(Deadline)
        .where(Deadline.id == deadline_id, Deadline.hackathon_id == hackathon_id)
    )
    deadline = result.scalar_one_or_none()
    
    if not deadline:
        raise HTTPException(status_code=404, detail="Deadline not found")
    
    await db.delete(deadline)
    await db.commit()
    
    return {"message": "Deadline deleted successfully"}


# Добавлен эндпоинт /timer в deadlines.py для совместимости
@router.get("/../timer", response_model=TimerResponse)
async def get_timer(
    hackathon_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get timer information for hackathon"""
    result = await db.execute(select(Hackathon).where(Hackathon.id == hackathon_id))
    hackathon = result.scalar_one_or_none()
    
    if not hackathon:
        raise HTTPException(status_code=404, detail="Hackathon not found")
    
    now_aware = datetime.now(timezone.utc)
    now_naive = now_aware.replace(tzinfo=None)
    
    # Get next deadline
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
        if hackathon.end_at.replace(tzinfo=None) < now_naive:
            current_phase = "finished"
        elif hackathon.start_at.replace(tzinfo=None) > now_naive:
            current_phase = "not_started"
        else:
            current_phase = "active"
    
    if next_deadline:
        next_deadline_title = next_deadline.title
        next_deadline_at = next_deadline.deadline_at
        deadline_aware = next_deadline.deadline_at.replace(tzinfo=timezone.utc)
        seconds_remaining = int((deadline_aware - now_aware).total_seconds())
    
    return TimerResponse(
        hackathon_status=hackathon.status.value,
        current_phase=current_phase,
        next_deadline_title=next_deadline_title,
        next_deadline_at=next_deadline_at,
        seconds_remaining=seconds_remaining
    )