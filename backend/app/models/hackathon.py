# backend/app/models/hackathon.py
from sqlalchemy import Column, String, DateTime, Boolean, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy import Enum as PgEnum
from sqlalchemy.orm import relationship
from enum import Enum
from app.models.base import Base

class HackathonStatus(str, Enum):
    DRAFT = "draft"
    ACTIVE = "active"
    FINISHED = "finished"

class Hackathon(Base):
    __tablename__ = "hackathons"
    
    title = Column(String(200), nullable=False)
    description = Column(String)
    start_at = Column(DateTime, nullable=False)
    end_at = Column(DateTime, nullable=False)
    status = Column(PgEnum(HackathonStatus), default=HackathonStatus.DRAFT, nullable=False)
    
    results_published = Column(Boolean, default=False)
    results_published_at = Column(DateTime, nullable=True)
    results_frozen = Column(Boolean, default=False)
    results_frozen_at = Column(DateTime, nullable=True)
    leaderboard_updated_at = Column(DateTime, nullable=True)
    
    # Relationships
    teams = relationship("Team", back_populates="hackathon", cascade="all, delete-orphan")
    criteria = relationship("Criterion", back_populates="hackathon", cascade="all, delete-orphan")
    expert_assignments = relationship("ExpertTeamAssignment", back_populates="hackathon", cascade="all, delete-orphan")
    evaluations = relationship("Evaluation", back_populates="hackathon", cascade="all, delete-orphan")
    deadlines = relationship("Deadline", back_populates="hackathon", cascade="all, delete-orphan")
    team_results = relationship("TeamResult", back_populates="hackathon", cascade="all, delete-orphan")
    audit_logs = relationship("AuditLog", back_populates="hackathon", cascade="all, delete-orphan")
    
    __table_args__ = (
        CheckConstraint("start_at < end_at", name="hackathons_date_chk"),
    )