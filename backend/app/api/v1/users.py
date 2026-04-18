# backend/app/api/v1/users.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import Optional
from uuid import UUID

from app.core.database import get_db
from app.dependencies.auth import get_current_user, admin_required
from app.models.user import User
from app.models.role import Role
from app.schemas.user import UserCreate, UserUpdate, UserResponse, UserListResponse, ResetPasswordRequest
from app.core.security import get_password_hash

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
    query = select(User)
    count_query = select(func.count()).select_from(User)
    
    # Apply filters
    if role:
        query = query.join(Role).where(Role.code == role)
        count_query = count_query.join(Role).where(Role.code == role)
    
    if search:
        search_filter = (User.login.ilike(f"%{search}%")) | (User.full_name.ilike(f"%{search}%"))
        query = query.where(search_filter)
        count_query = count_query.where(search_filter)
    
    if is_active is not None:
        query = query.where(User.is_active == is_active)
        count_query = count_query.where(User.is_active == is_active)
    
    # Get total count
    total_result = await db.execute(count_query)
    total = total_result.scalar_one()
    
    # Get paginated results
    query = query.order_by(User.created_at.desc())
    query = query.offset((page - 1) * page_size).limit(page_size)
    
    result = await db.execute(query)
    users = result.scalars().all()
    
    # Build response with role codes
    items = []
    for user in users:
        role_result = await db.execute(select(Role).where(Role.id == user.role_id))
        role_obj = role_result.scalar_one_or_none()
        
        items.append(UserResponse(
            id=user.id,
            login=user.login,
            full_name=user.full_name,
            role_code=role_obj.code if role_obj else "unknown",
            email=user.email,
            phone=user.phone,
            team_id=user.team_id,
            is_active=user.is_active,
            last_login_at=user.last_login_at,
            created_at=user.created_at
        ))
    
    return UserListResponse(
        items=items,
        page=page,
        page_size=page_size,
        total=total
    )


@router.post("/", response_model=UserResponse)
async def create_user(
    user_data: UserCreate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Create a new user (admin only)"""
    # Get role
    role_result = await db.execute(
        select(Role).where(Role.code == user_data.role_code)
    )
    role = role_result.scalar_one_or_none()
    
    if not role:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Role '{user_data.role_code}' not found"
        )
    
    # Check if login exists
    existing = await db.execute(
        select(User).where(User.login == user_data.login)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Login already taken"
        )
    
    new_user = User(
        login=user_data.login,
        password_hash=get_password_hash(user_data.password),
        full_name=user_data.full_name,
        email=user_data.email,
        phone=user_data.phone,
        role_id=role.id,
        team_id=user_data.team_id,
        is_active=user_data.is_active
    )
    
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    
    return UserResponse(
        id=new_user.id,
        login=new_user.login,
        full_name=new_user.full_name,
        role_code=role.code,
        email=new_user.email,
        phone=new_user.phone,
        team_id=new_user.team_id,
        is_active=new_user.is_active,
        last_login_at=new_user.last_login_at,
        created_at=new_user.created_at
    )


# Остальные методы аналогично...