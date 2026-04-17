# backend/app/api/v1/auth.py
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.services.auth_service import AuthService
from app.schemas.auth import LoginRequest, TokenResponse, RefreshTokenRequest, ChangePasswordRequest
from app.dependencies.auth import get_current_user
from app.models.user import User

router = APIRouter(prefix="/auth", tags=["Auth"])

@router.post("/login", response_model=TokenResponse)
async def login(
    request: LoginRequest,
    req: Request,
    db: AsyncSession = Depends(get_db)
):
    auth_service = AuthService(db)
    
    user = await auth_service.authenticate_user(request.login, request.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials or inactive account"
        )
    
    access_token, refresh_token = await auth_service.generate_tokens(user)
    
    user_info = await auth_service.get_user_info(user)
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user=user_info
    )

@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(
    request: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db)
):
    auth_service = AuthService(db)
    
    user = await auth_service.validate_refresh_token(request.refresh_token)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token"
        )
    
    access_token, refresh_token = await auth_service.generate_tokens(user)
    await auth_service.revoke_refresh_token(request.refresh_token)
    
    user_info = await auth_service.get_user_info(user)
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user=user_info
    )

@router.post("/logout")
async def logout(
    request: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db)
):
    auth_service = AuthService(db)
    await auth_service.revoke_refresh_token(request.refresh_token)
    return {"message": "Logged out successfully"}

@router.get("/me", response_model=TokenResponse)
async def get_me(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    auth_service = AuthService(db)
    user_info = await auth_service.get_user_info(current_user)
    
    return TokenResponse(
        access_token="",  # Not needed for this endpoint
        refresh_token="",
        user=user_info
    )

@router.post("/change-password")
async def change_password(
    request: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    auth_service = AuthService(db)
    
    success = await auth_service.change_password(
        current_user,
        request.old_password,
        request.new_password
    )
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid old password"
        )
    
    return {"message": "Password changed successfully"}