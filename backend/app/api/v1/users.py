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
from app.core.security import get_password_hash, verify_password

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
    
    total_result = await db.execute(count_query)
    total = total_result.scalar_one()
    
    query = query.order_by(User.created_at.desc())
    query = query.offset((page - 1) * page_size).limit(page_size)
    
    result = await db.execute(query)
    users = result.scalars().all()
    
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


@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
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
    
    # Check if email exists (if provided)
    if user_data.email:
        existing_email = await db.execute(
            select(User).where(User.email == user_data.email)
        )
        if existing_email.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
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


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Get user by ID (admin only)"""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    role_result = await db.execute(select(Role).where(Role.id == user.role_id))
    role_obj = role_result.scalar_one_or_none()
    
    return UserResponse(
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
    )


@router.patch("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: UUID,
    user_data: UserUpdate,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Update user (admin only)"""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    update_data = user_data.model_dump(exclude_unset=True)
    
    # Handle role change
    if "role_code" in update_data:
        role_code = update_data.pop("role_code")
        role_result = await db.execute(select(Role).where(Role.code == role_code))
        role = role_result.scalar_one_or_none()
        if not role:
            raise HTTPException(status_code=400, detail=f"Role '{role_code}' not found")
        user.role_id = role.id
    
    # Handle password change
    if "password" in update_data:
        user.password_hash = get_password_hash(update_data.pop("password"))
    
    # Update other fields
    for field, value in update_data.items():
        if value is not None:
            setattr(user, field, value)
    
    await db.commit()
    await db.refresh(user)
    
    role_result = await db.execute(select(Role).where(Role.id == user.role_id))
    role_obj = role_result.scalar_one_or_none()
    
    return UserResponse(
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
    )


@router.delete("/{user_id}")
async def delete_user(
    user_id: UUID,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Delete user (admin only)"""
    if user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot delete yourself")
    
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    await db.delete(user)
    await db.commit()
    
    return {"message": "User deleted successfully"}


@router.post("/{user_id}/reset-password")
async def reset_user_password(
    user_id: UUID,
    request: ResetPasswordRequest,
    current_user: User = Depends(admin_required),
    db: AsyncSession = Depends(get_db)
):
    """Reset user password (admin only)"""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.password_hash = get_password_hash(request.new_password)
    await db.commit()
    
    return {"message": "Password reset successfully"}