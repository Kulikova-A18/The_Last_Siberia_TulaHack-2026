# backend/app/dependencies/auth.py
from fastapi import Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Callable, Awaitable
from functools import wraps
from app.core.database import get_db
from app.core.security import get_current_user as get_user_from_token
from app.models.user import User
from app.models.role import Role, Permission

async def get_current_user(
    request: Request,
    db: AsyncSession = Depends(get_db)
) -> User:
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid authorization header"
        )
    
    token = auth_header.split(" ")[1]
    user = await get_user_from_token(token, db)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token"
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is disabled"
        )
    
    return user

def require_role(required_role_codes: List[str]) -> Callable:
    """Dependency factory for role-based access control"""
    async def role_checker(
        current_user: User = Depends(get_current_user),
        db: AsyncSession = Depends(get_db)
    ) -> User:
        from sqlalchemy import select
        
        result = await db.execute(
            select(Role).where(Role.id == current_user.role_id)
        )
        role = result.scalar_one_or_none()
        
        if not role or role.code not in required_role_codes:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Required roles: {', '.join(required_role_codes)}"
            )
        return current_user
    return role_checker

def require_permission(required_permission_codes: List[str]) -> Callable:
    """Dependency factory for permission-based access control"""
    async def permission_checker(
        current_user: User = Depends(get_current_user),
        db: AsyncSession = Depends(get_db)
    ) -> User:
        from sqlalchemy import select
        
        result = await db.execute(
            select(Role).where(Role.id == current_user.role_id)
        )
        role = result.scalar_one_or_none()
        
        if not role:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User role not found"
            )
        
        result = await db.execute(
            select(Permission.code)
            .join(Role.permissions)
            .where(Role.id == role.id)
        )
        user_permissions = [p for p in result.scalars().all()]
        
        if not all(perm in user_permissions for perm in required_permission_codes):
            missing = [p for p in required_permission_codes if p not in user_permissions]
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Missing permissions: {', '.join(missing)}"
            )
        
        return current_user
    return permission_checker

# Pre-configured role checkers - these are now async functions
async def admin_required(current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)) -> User:
    from sqlalchemy import select
    result = await db.execute(select(Role).where(Role.id == current_user.role_id))
    role = result.scalar_one_or_none()
    if not role or role.code != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied. Admin role required."
        )
    return current_user

async def expert_required(current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)) -> User:
    from sqlalchemy import select
    result = await db.execute(select(Role).where(Role.id == current_user.role_id))
    role = result.scalar_one_or_none()
    if not role or role.code not in ["admin", "expert"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied. Expert or Admin role required."
        )
    return current_user

async def team_required(current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)) -> User:
    from sqlalchemy import select
    result = await db.execute(select(Role).where(Role.id == current_user.role_id))
    role = result.scalar_one_or_none()
    if not role or role.code not in ["admin", "team"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied. Team or Admin role required."
        )
    return current_user