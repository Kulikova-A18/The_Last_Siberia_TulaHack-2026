# backend/app/models/team_result.py
from sqlalchemy import Column, Numeric, Integer, ForeignKey, DateTime, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy import Enum as PgEnum
from sqlalchemy.orm import relationship
from enum import Enum
from app.models.base import Base

class ResultStatus(str, Enum):
    NOT_STARTED = "not_started"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"

class TeamResult(Base):
    __tablename__ = "team_results"
    
    hackathon_id = Column(UUID(as_uuid=True), ForeignKey("hackathons.id", ondelete="CASCADE"), nullable=False)
    team_id = Column(UUID(as_uuid=True), nullable=False)
    
    final_score = Column(Numeric(7, 3), default=0, nullable=False)
    place = Column(Integer, nullable=True)
    evaluated_by_count = Column(Integer, default=0, nullable=False)
    status = Column(PgEnum(ResultStatus), default=ResultStatus.NOT_STARTED, nullable=False)
    recalculated_at = Column(DateTime, nullable=True)
    
    # Relationships
    hackathon = relationship("Hackathon", back_populates="team_results")
    team = relationship("Team", back_populates="team_result")
    items = relationship("TeamResultItem", back_populates="team_result", cascade="all, delete-orphan")
    
    __table_args__ = (
        CheckConstraint("final_score >= 0 AND final_score <= 100", name="team_results_score_chk"),
        CheckConstraint("place IS NULL OR place > 0", name="team_results_place_chk"),
        CheckConstraint("evaluated_by_count >= 0", name="team_results_evaluated_by_chk"),
    )

class TeamResultItem(Base):
    __tablename__ = "team_result_items"
    
    team_result_id = Column(UUID(as_uuid=True), ForeignKey("team_results.id", ondelete="CASCADE"), nullable=False)
    criterion_id = Column(UUID(as_uuid=True), ForeignKey("criteria.id", ondelete="RESTRICT"), nullable=False)
    
    avg_raw_score = Column(Numeric(6, 2), default=0, nullable=False)
    avg_normalized_score = Column(Numeric(7, 4), default=0, nullable=False)
    weighted_score = Column(Numeric(7, 3), default=0, nullable=False)
    
    # Relationships
    team_result = relationship("TeamResult", back_populates="items")
    criterion = relationship("Criterion", back_populates="team_result_items")
    
    __table_args__ = (
        CheckConstraint("avg_raw_score >= 0", name="team_result_items_avg_raw_chk"),
        CheckConstraint("avg_normalized_score >= 0 AND avg_normalized_score <= 1", name="team_result_items_avg_norm_chk"),
        CheckConstraint("weighted_score >= 0 AND weighted_score <= 100", name="team_result_items_weighted_chk"),
    )