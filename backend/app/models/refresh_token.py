# backend/app/models/refresh_token.py
from sqlalchemy import Column, String, ForeignKey, DateTime, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID, INET
from sqlalchemy.orm import relationship
from app.models.base import Base, IDMixin, TimestampMixin


class RefreshToken(Base, IDMixin, TimestampMixin):
    __tablename__ = "refresh_tokens"
    
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    token_hash = Column(String(255), unique=True, nullable=False)
    expires_at = Column(DateTime, nullable=False)
    revoked_at = Column(DateTime, nullable=True)
    user_agent = Column(String(255))
    ip_address = Column(INET)
    
    # Relationships
    user = relationship("User", back_populates="refresh_tokens")
    
    __table_args__ = (
        CheckConstraint("expires_at > created_at", name="refresh_tokens_expires_chk"),
    )