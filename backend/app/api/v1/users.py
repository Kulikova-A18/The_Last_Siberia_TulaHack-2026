# backend/app/api/v1/users.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
from uuid import UUID

from app.core.database import get_db
from app.dependencies.auth import get_current_user, admin_required
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate, UserResponse, UserListResponse, ResetPasswordRequest

router = APIRouter(prefix="/users", tags=["Users"])

@router.get("/", response_model=UserListResponse)
async def get_users(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    role: Optional[str] = None,
    search: Optional[str] = None,
    is_active: Optional[bool] = None,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Get list of users (admin only)"""
    # TODO: Implement actual database query
    return UserListResponse(
        items=[],
        page=page,
        page_size=page_size,
        total=0
    )

@router.post("/", response_model=UserResponse)
async def create_user(
    user_data: UserCreate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Create a new user (admin only)"""
    # TODO: Implement user creation
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="User creation not implemented yet"
    )

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Get user by ID (admin only)"""
    # TODO: Implement user retrieval
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="User retrieval not implemented yet"
    )

@router.patch("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: UUID,
    user_data: UserUpdate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Update user (admin only)"""
    # TODO: Implement user update
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="User update not implemented yet"
    )

@router.post("/{user_id}/reset-password")
async def reset_password(
    user_id: UUID,
    request: ResetPasswordRequest,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Reset user password (admin only)"""
    # TODO: Implement password reset
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Password reset not implemented yet"
    )

@router.post("/{user_id}/activate")
async def activate_user(
    user_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Activate user (admin only)"""
    # TODO: Implement user activation
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="User activation not implemented yet"
    )

@router.post("/{user_id}/deactivate")
async def deactivate_user(
    user_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Deactivate user (admin only)"""
    # TODO: Implement user deactivation
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="User deactivation not implemented yet"
    )