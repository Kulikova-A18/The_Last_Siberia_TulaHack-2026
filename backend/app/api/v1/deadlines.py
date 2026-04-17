# backend/app/api/v1/deadlines.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID

from app.core.database import get_db
from app.dependencies.auth import get_current_user, admin_required
from app.models.user import User
from app.schemas.deadline import DeadlineCreate, DeadlineUpdate, DeadlineResponse, TimerResponse

router = APIRouter(prefix="/hackathons/{hackathon_id}/deadlines", tags=["Deadlines"])

@router.get("/", response_model=list[DeadlineResponse])
async def get_deadlines(
    hackathon_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get all deadlines for hackathon"""
    # TODO: Implement deadlines list
    return []

@router.post("/", response_model=DeadlineResponse)
async def create_deadline(
    hackathon_id: UUID,
    deadline_data: DeadlineCreate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Create a new deadline (admin only)"""
    # TODO: Implement deadline creation
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.get("/{deadline_id}", response_model=DeadlineResponse)
async def get_deadline(
    hackathon_id: UUID,
    deadline_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get deadline by ID"""
    # TODO: Implement deadline retrieval
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.patch("/{deadline_id}", response_model=DeadlineResponse)
async def update_deadline(
    hackathon_id: UUID,
    deadline_id: UUID,
    deadline_data: DeadlineUpdate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Update deadline (admin only)"""
    # TODO: Implement deadline update
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.delete("/{deadline_id}")
async def delete_deadline(
    hackathon_id: UUID,
    deadline_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Delete deadline (admin only)"""
    # TODO: Implement deadline deletion
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.get("/timer", response_model=TimerResponse)
async def get_timer(
    hackathon_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get timer information"""
    # TODO: Implement timer retrieval
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )