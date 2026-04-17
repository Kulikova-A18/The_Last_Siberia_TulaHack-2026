# backend/app/api/v1/roles.py
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from app.core.database import get_db
from app.dependencies.auth import get_current_user, admin_required
from app.models.user import User
from app.schemas.role import RoleResponse, PermissionResponse

router = APIRouter(prefix="/roles", tags=["Roles"])

@router.get("/", response_model=List[RoleResponse])
async def get_roles(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get list of all roles"""
    # TODO: Implement roles retrieval
    return []

@router.get("/permissions", response_model=List[PermissionResponse])
async def get_permissions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get list of all permissions"""
    # TODO: Implement permissions retrieval
    return []