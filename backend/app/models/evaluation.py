# backend/app/models/evaluation.py
from sqlalchemy import Column, String, ForeignKey, DateTime, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy import Enum as PgEnum
from sqlalchemy.orm import relationship
from enum import Enum
from app.models.base import Base

class EvaluationStatus(str, Enum):
    DRAFT = "draft"
    SUBMITTED = "submitted"

class Evaluation(Base):
    __tablename__ = "evaluations"
    
    hackathon_id = Column(UUID(as_uuid=True), ForeignKey("hackathons.id", ondelete="CASCADE"), nullable=False)
    expert_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"), nullable=False)
    team_id = Column(UUID(as_uuid=True), nullable=False)
    
    status = Column(PgEnum(EvaluationStatus), default=EvaluationStatus.DRAFT, nullable=False)
    overall_comment = Column(String)
    submitted_at = Column(DateTime, nullable=True)
    
    # Relationships
    hackathon = relationship("Hackathon", back_populates="evaluations")
    expert = relationship("User", foreign_keys=[expert_user_id], back_populates="evaluations")
    team = relationship("Team", back_populates="evaluations")
    items = relationship("EvaluationItem", back_populates="evaluation", cascade="all, delete-orphan")
    assignment = relationship("ExpertTeamAssignment", foreign_keys=[hackathon_id, expert_user_id, team_id], viewonly=True)
    
    __table_args__ = (
        CheckConstraint(
            "(status = 'draft' AND submitted_at IS NULL) OR (status = 'submitted' AND submitted_at IS NOT NULL)",
            name="evaluations_status_chk"
        ),
    )