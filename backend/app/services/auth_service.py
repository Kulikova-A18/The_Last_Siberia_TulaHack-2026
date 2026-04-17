# backend/app/services/auth_service.py
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime
from uuid import UUID
import hashlib
import secrets

from app.models.user import User
from app.models.refresh_token import RefreshToken
from app.models.role import Role
from app.core.security import verify_password, get_password_hash, create_access_token, create_refresh_token, decode_token
from app.schemas.auth import UserInfo

class AuthService:
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def authenticate_user(self, login: str, password: str) -> User | None:
        result = await self.db.execute(
            select(User).where(User.login == login)
        )
        user = result.scalar_one_or_none()
        
        if not user or not verify_password(password, user.password_hash):
            return None
        
        if not user.is_active:
            return None
        
        user.last_login_at = datetime.utcnow()
        await self.db.commit()
        
        return user
    
    async def create_refresh_token(self, user_id: UUID, user_agent: str = None, ip_address: str = None) -> str:
        token = secrets.token_urlsafe(64)
        token_hash = hashlib.sha256(token.encode()).hexdigest()
        
        from datetime import timedelta
        expires_at = datetime.utcnow() + timedelta(days=7)
        
        refresh_token = RefreshToken(
            user_id=user_id,
            token_hash=token_hash,
            expires_at=expires_at,
            user_agent=user_agent,
            ip_address=ip_address
        )
        
        self.db.add(refresh_token)
        await self.db.commit()
        
        return token
    
    async def validate_refresh_token(self, token: str) -> User | None:
        token_hash = hashlib.sha256(token.encode()).hexdigest()
        
        result = await self.db.execute(
            select(RefreshToken).where(
                RefreshToken.token_hash == token_hash,
                RefreshToken.revoked_at.is_(None),
                RefreshToken.expires_at > datetime.utcnow()
            )
        )
        refresh_token = result.scalar_one_or_none()
        
        if not refresh_token:
            return None
        
        result = await self.db.execute(
            select(User).where(User.id == refresh_token.user_id, User.is_active == True)
        )
        return result.scalar_one_or_none()
    
    async def revoke_refresh_token(self, token: str):
        token_hash = hashlib.sha256(token.encode()).hexdigest()
        
        result = await self.db.execute(
            select(RefreshToken).where(RefreshToken.token_hash == token_hash)
        )
        refresh_token = result.scalar_one_or_none()
        
        if refresh_token:
            refresh_token.revoked_at = datetime.utcnow()
            await self.db.commit()
    
    async def get_user_info(self, user: User) -> UserInfo:
        role_result = await self.db.execute(
            select(Role).where(Role.id == user.role_id)
        )
        role = role_result.scalar_one_or_none()
        
        return UserInfo(
            id=user.id,
            login=user.login,
            full_name=user.full_name,
            role=role.code if role else "unknown",
            team_id=user.team_id,
            is_active=user.is_active
        )
    
    async def change_password(self, user: User, old_password: str, new_password: str) -> bool:
        if not verify_password(old_password, user.password_hash):
            return False
        
        user.password_hash = get_password_hash(new_password)
        await self.db.commit()
        return True
    
    async def generate_tokens(self, user: User) -> tuple[str, str]:
        access_token = create_access_token(data={"sub": str(user.id)})
        refresh_token = create_refresh_token(data={"sub": str(user.id)})
        return access_token, refresh_token