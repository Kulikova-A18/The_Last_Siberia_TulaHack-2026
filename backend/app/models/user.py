# backend/app/models/user.py
from sqlalchemy import Column, String, Boolean, ForeignKey, DateTime, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.models.base import Base

class User(Base):
    __tablename__ = "users"
    
    login = Column(String(50), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    full_name = Column(String(200), nullable=False)
    email = Column(String(100))
    phone = Column(String(32))
    
    role_id = Column(UUID(as_uuid=True), ForeignKey("roles.id", ondelete="RESTRICT"), nullable=False)
    team_id = Column(UUID(as_uuid=True), ForeignKey("teams.id", ondelete="SET NULL"), nullable=True)
    
    is_active = Column(Boolean, default=True)
    last_login_at = Column(DateTime, nullable=True)
    
    # Relationships
    role = relationship("Role", back_populates="users")
    team = relationship("Team", back_populates="account_user")
    refresh_tokens = relationship("RefreshToken", back_populates="user", cascade="all, delete-orphan")
    expert_assignments = relationship("ExpertTeamAssignment", foreign_keys="ExpertTeamAssignment.expert_user_id", back_populates="expert")
    evaluations = relationship("Evaluation", foreign_keys="Evaluation.expert_user_id", back_populates="expert")
    audit_logs = relationship("AuditLog", back_populates="actor")
    
    __table_args__ = (
        CheckConstraint("char_length(login) >= 3", name="users_login_len_chk"),
    )