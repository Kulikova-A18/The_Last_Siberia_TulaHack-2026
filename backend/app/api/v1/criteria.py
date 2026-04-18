# backend/app/api/v1/criteria.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from uuid import UUID

from app.core.database import get_db
from app.dependencies.auth import get_current_user, admin_required
from app.models.user import User
from app.models.criterion import Criterion
from app.models.hackathon import Hackathon
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


@router.post("/", response_model=CriterionResponse, status_code=status.HTTP_201_CREATED)
async def create_criterion(
    hackathon_id: UUID,
    criterion_data: CriterionCreate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Create a new criterion (admin only)"""
    # Verify hackathon exists
    hackathon_result = await db.execute(select(Hackathon).where(Hackathon.id == hackathon_id))
    if not hackathon_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Hackathon not found")
    
    # Check title uniqueness
    existing = await db.execute(
        select(Criterion).where(
            Criterion.hackathon_id == hackathon_id,
            Criterion.title == criterion_data.title
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Criterion with this title already exists")
    
    # Get next sort order
    max_order_result = await db.execute(
        select(func.max(Criterion.sort_order)).where(Criterion.hackathon_id == hackathon_id)
    )
    max_order = max_order_result.scalar_one() or 0
    sort_order = max_order + 1
    
    new_criterion = Criterion(
        hackathon_id=hackathon_id,
        title=criterion_data.title,
        description=criterion_data.description,
        max_score=criterion_data.max_score,
        weight_percent=criterion_data.weight_percent,
        sort_order=criterion_data.sort_order if criterion_data.sort_order else sort_order,
        is_active=criterion_data.is_active
    )
    
    db.add(new_criterion)
    await db.commit()
    await db.refresh(new_criterion)
    
    return CriterionResponse(
        id=new_criterion.id,
        title=new_criterion.title,
        description=new_criterion.description,
        max_score=float(new_criterion.max_score),
        weight_percent=float(new_criterion.weight_percent),
        sort_order=new_criterion.sort_order,
        is_active=new_criterion.is_active,
        created_at=new_criterion.created_at,
        updated_at=new_criterion.updated_at
    )


@router.get("/{criterion_id}", response_model=CriterionResponse)
async def get_criterion(
    hackathon_id: UUID,
    criterion_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get criterion by ID"""
    result = await db.execute(
        select(Criterion).where(
            Criterion.id == criterion_id,
            Criterion.hackathon_id == hackathon_id
        )
    )
    criterion = result.scalar_one_or_none()
    
    if not criterion:
        raise HTTPException(status_code=404, detail="Criterion not found")
    
    return CriterionResponse(
        id=criterion.id,
        title=criterion.title,
        description=criterion.description,
        max_score=float(criterion.max_score),
        weight_percent=float(criterion.weight_percent),
        sort_order=criterion.sort_order,
        is_active=criterion.is_active,
        created_at=criterion.created_at,
        updated_at=criterion.updated_at
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
    result = await db.execute(
        select(Criterion).where(
            Criterion.id == criterion_id,
            Criterion.hackathon_id == hackathon_id
        )
    )
    criterion = result.scalar_one_or_none()
    
    if not criterion:
        raise HTTPException(status_code=404, detail="Criterion not found")
    
    update_data = criterion_data.model_dump(exclude_unset=True)
    
    # Check title uniqueness if changing
    if "title" in update_data and update_data["title"] != criterion.title:
        existing = await db.execute(
            select(Criterion).where(
                Criterion.hackathon_id == hackathon_id,
                Criterion.title == update_data["title"],
                Criterion.id != criterion_id
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Criterion with this title already exists")
    
    for field, value in update_data.items():
        if value is not None:
            setattr(criterion, field, value)
    
    await db.commit()
    await db.refresh(criterion)
    
    return CriterionResponse(
        id=criterion.id,
        title=criterion.title,
        description=criterion.description,
        max_score=float(criterion.max_score),
        weight_percent=float(criterion.weight_percent),
        sort_order=criterion.sort_order,
        is_active=criterion.is_active,
        created_at=criterion.created_at,
        updated_at=criterion.updated_at
    )


@router.delete("/{criterion_id}")
async def delete_criterion(
    hackathon_id: UUID,
    criterion_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Delete criterion (admin only)"""
    result = await db.execute(
        select(Criterion).where(
            Criterion.id == criterion_id,
            Criterion.hackathon_id == hackathon_id
        )
    )
    criterion = result.scalar_one_or_none()
    
    if not criterion:
        raise HTTPException(status_code=404, detail="Criterion not found")
    
    await db.delete(criterion)
    await db.commit()
    
    return {"message": "Criterion deleted successfully"}


@router.post("/reorder")
async def reorder_criteria(
    hackathon_id: UUID,
    reorder_data: CriteriaReorderRequest,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Reorder criteria (admin only)"""
    for item in reorder_data.order:
        result = await db.execute(
            select(Criterion).where(
                Criterion.id == item.criterion_id,
                Criterion.hackathon_id == hackathon_id
            )
        )
        criterion = result.scalar_one_or_none()
        if criterion:
            criterion.sort_order = item.sort_order
    
    await db.commit()
    
    return {"message": "Criteria reordered successfully"}