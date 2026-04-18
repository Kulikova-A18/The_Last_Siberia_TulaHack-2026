# backend/app/api/v1/criteria.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from uuid import UUID

from app.core.database import get_db
from app.dependencies.auth import get_current_user, admin_required
from app.models.user import User
from app.models.criterion import Criterion
from app.schemas.criterion import (
    CriterionCreate, CriterionUpdate, CriterionResponse, 
    CriteriaListResponse, CriteriaReorderRequest
)

router = APIRouter(prefix="/hackathons/{hackathon_id}/criteria", tags=["Criteria"])


@router.get("/", response_model=CriteriaListResponse)
async def get_criteria(
    hackathon_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get all criteria for hackathon"""
    result = await db.execute(
        select(Criterion)
        .where(Criterion.hackathon_id == hackathon_id)
        .order_by(Criterion.sort_order)
    )
    criteria = result.scalars().all()
    
    total_weight = sum(float(c.weight_percent) for c in criteria)
    weights_valid = abs(total_weight - 100.0) < 0.01
    
    items = [CriterionResponse(
        id=c.id,
        title=c.title,
        description=c.description,
        max_score=float(c.max_score),
        weight_percent=float(c.weight_percent),
        sort_order=c.sort_order,
        is_active=c.is_active,
        created_at=c.created_at,
        updated_at=c.updated_at
    ) for c in criteria]
    
    return CriteriaListResponse(
        items=items,
        total_weight=total_weight,
        weights_valid=weights_valid
    )

@router.post("/", response_model=CriterionResponse)
async def create_criterion(
    hackathon_id: UUID,
    criterion_data: CriterionCreate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Create a new criterion (admin only)"""
    # TODO: Implement criterion creation
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.get("/{criterion_id}", response_model=CriterionResponse)
async def get_criterion(
    hackathon_id: UUID,
    criterion_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get criterion by ID"""
    # TODO: Implement criterion retrieval
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.patch("/{criterion_id}", response_model=CriterionResponse)
async def update_criterion(
    hackathon_id: UUID,
    criterion_id: UUID,
    criterion_data: CriterionUpdate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Update criterion (admin only)"""
    # TODO: Implement criterion update
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.delete("/{criterion_id}")
async def delete_criterion(
    hackathon_id: UUID,
    criterion_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Delete criterion (admin only)"""
    # TODO: Implement criterion deletion
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )

@router.post("/reorder")
async def reorder_criteria(
    hackathon_id: UUID,
    reorder_data: CriteriaReorderRequest,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Reorder criteria (admin only)"""
    # TODO: Implement criteria reordering
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not implemented yet"
    )