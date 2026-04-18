# backend/app/api/v1/hackathons.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from uuid import UUID

from app.core.database import get_db
from app.dependencies.auth import get_current_user, admin_required
from app.models.user import User
from app.models.hackathon import Hackathon, HackathonStatus
from app.schemas.hackathon import HackathonCreate, HackathonUpdate, HackathonResponse

router = APIRouter(prefix="/hackathons", tags=["Hackathons"])


@router.get("/active", response_model=HackathonResponse)
async def get_active_hackathon(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get the active hackathon"""
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
    
    return hackathon


@router.get("/", response_model=list[HackathonResponse])
async def get_hackathons(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get all hackathons"""
    result = await db.execute(
        select(Hackathon).order_by(Hackathon.created_at.desc())
    )
    return list(result.scalars().all())


@router.post("/", response_model=HackathonResponse)
async def create_hackathon(
    hackathon_data: HackathonCreate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Create a new hackathon (admin only)"""
    from datetime import datetime
    
    new_hackathon = Hackathon(
        title=hackathon_data.title,
        description=hackathon_data.description,
        start_at=hackathon_data.start_at,
        end_at=hackathon_data.end_at,
        status=HackathonStatus.DRAFT
    )
    
    db.add(new_hackathon)
    await db.commit()
    await db.refresh(new_hackathon)
    
    return new_hackathon


@router.get("/{hackathon_id}", response_model=HackathonResponse)
async def get_hackathon(
    hackathon_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get hackathon by ID"""
    result = await db.execute(
        select(Hackathon).where(Hackathon.id == hackathon_id)
    )
    hackathon = result.scalar_one_or_none()
    
    if not hackathon:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hackathon not found"
        )
    
    return hackathon


@router.patch("/{hackathon_id}", response_model=HackathonResponse)
async def update_hackathon(
    hackathon_id: UUID,
    hackathon_data: HackathonUpdate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Update hackathon (admin only)"""
    result = await db.execute(
        select(Hackathon).where(Hackathon.id == hackathon_id)
    )
    hackathon = result.scalar_one_or_none()
    
    if not hackathon:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hackathon not found"
        )
    
    # Update fields
    update_data = hackathon_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        if field == "status" and value:
            value = HackathonStatus(value)
        setattr(hackathon, field, value)
    
    await db.commit()
    await db.refresh(hackathon)
    
    return hackathon


@router.post("/{hackathon_id}/start")
async def start_hackathon(
    hackathon_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Start hackathon (admin only)"""
    result = await db.execute(
        select(Hackathon).where(Hackathon.id == hackathon_id)
    )
    hackathon = result.scalar_one_or_none()
    
    if not hackathon:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hackathon not found"
        )
    
    hackathon.status = HackathonStatus.ACTIVE
    await db.commit()
    
    return {"message": "Hackathon started", "id": str(hackathon_id)}


@router.post("/{hackathon_id}/finish")
async def finish_hackathon(
    hackathon_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Finish hackathon (admin only)"""
    result = await db.execute(
        select(Hackathon).where(Hackathon.id == hackathon_id)
    )
    hackathon = result.scalar_one_or_none()
    
    if not hackathon:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hackathon not found"
        )
    
    hackathon.status = HackathonStatus.FINISHED
    await db.commit()
    
    return {"message": "Hackathon finished", "id": str(hackathon_id)}