# backend/app/api/v1/hackathons.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID

from app.core.database import get_db
from app.dependencies.auth import get_current_user, admin_required
from app.models.user import User
from app.schemas.hackathon import HackathonCreate, HackathonUpdate, HackathonResponse

router = APIRouter(prefix="/hackathons", tags=["Hackathons"])

@router.get("/active", response_model=HackathonResponse)
async def get_active_hackathon(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get the active hackathon"""
    # TODO: Implement active hackathon retrieval
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.get("/", response_model=list[HackathonResponse])
async def get_hackathons(
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Get all hackathons (admin only)"""
    # TODO: Implement hackathons list
    return []

@router.post("/", response_model=HackathonResponse)
async def create_hackathon(
    hackathon_data: HackathonCreate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Create a new hackathon (admin only)"""
    # TODO: Implement hackathon creation
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.get("/{hackathon_id}", response_model=HackathonResponse)
async def get_hackathon(
    hackathon_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get hackathon by ID"""
    # TODO: Implement hackathon retrieval
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.patch("/{hackathon_id}", response_model=HackathonResponse)
async def update_hackathon(
    hackathon_id: UUID,
    hackathon_data: HackathonUpdate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Update hackathon (admin only)"""
    # TODO: Implement hackathon update
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.post("/{hackathon_id}/start")
async def start_hackathon(
    hackathon_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Start hackathon (admin only)"""
    # TODO: Implement hackathon start
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.post("/{hackathon_id}/finish")
async def finish_hackathon(
    hackathon_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Finish hackathon (admin only)"""
    # TODO: Implement hackathon finish
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )