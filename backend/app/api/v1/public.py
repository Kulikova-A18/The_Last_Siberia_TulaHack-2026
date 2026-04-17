# backend/app/api/v1/public.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID

from app.core.database import get_db
from app.schemas.public import (
    PublicLeaderboardResponse, PublicTimerResponse, PublicWinnersResponse, PublicHackathonResponse
)

router = APIRouter(prefix="/public", tags=["Public"])

@router.get("/hackathons/active", response_model=PublicHackathonResponse)
async def get_active_public_hackathon(
    db: AsyncSession = Depends(get_db)
):
    """Get active hackathon for public view"""
    # TODO: Implement active hackathon retrieval
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.get("/hackathons/{hackathon_id}/leaderboard", response_model=PublicLeaderboardResponse)
async def get_public_leaderboard(
    hackathon_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """Get public leaderboard"""
    # TODO: Implement public leaderboard
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.get("/hackathons/{hackathon_id}/timer", response_model=PublicTimerResponse)
async def get_public_timer(
    hackathon_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """Get public timer"""
    # TODO: Implement public timer
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.get("/hackathons/{hackathon_id}/winners", response_model=PublicWinnersResponse)
async def get_public_winners(
    hackathon_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """Get public winners"""
    # TODO: Implement public winners
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )