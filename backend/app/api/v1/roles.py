# backend/app/api/v1/roles.py
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List

from app.core.database import get_db
from app.dependencies.auth import get_current_user
from app.models.user import User
from app.models.role import Role, Permission
from app.schemas.role import RoleResponse, PermissionResponse

router = APIRouter(prefix="/roles", tags=["Roles"])


@router.get("/", response_model=List[RoleResponse])
async def get_roles(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get list of all roles"""
    result = await db.execute(select(Role).order_by(Role.code))
    roles = result.scalars().all()
    
    return [RoleResponse(
        id=r.id,
        code=r.code,
        name=r.name,
        created_at=getattr(r, 'created_at', None)
    ) for r in roles]


@router.get("/permissions", response_model=List[PermissionResponse])
async def get_permissions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get list of all permissions"""
    result = await db.execute(select(Permission).order_by(Permission.code))
    permissions = result.scalars().all()
    
    return [PermissionResponse(
        id=p.id,
        code=p.code,
        name=p.name,
        description=p.description
    ) for p in permissions]