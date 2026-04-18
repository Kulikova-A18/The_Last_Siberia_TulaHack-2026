# backend/app/models/evaluation.py
from sqlalchemy import Column, String, ForeignKey, DateTime, CheckConstraint, ForeignKeyConstraint, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy import Enum as PgEnum
from sqlalchemy.orm import relationship
from enum import Enum
from app.models.base import Base, IDMixin, TimestampMixin


class EvaluationStatus(str, Enum):
    DRAFT = "draft"
    SUBMITTED = "submitted"


class Evaluation(Base, IDMixin, TimestampMixin):
    __tablename__ = "evaluations"
    
    hackathon_id = Column(UUID(as_uuid=True), ForeignKey("hackathons.id", ondelete="CASCADE"), nullable=False)
    expert_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"), nullable=False)
    team_id = Column(UUID(as_uuid=True), nullable=False)
    
    status = Column(PgEnum(EvaluationStatus), default=EvaluationStatus.DRAFT, nullable=False)
    overall_comment = Column(String)
    submitted_at = Column(DateTime(timezone=True), nullable=True)
    
    # Relationships
    hackathon = relationship("Hackathon", back_populates="evaluations")
    expert = relationship("User", foreign_keys=[expert_user_id], back_populates="evaluations")
    team = relationship(
        "Team", 
        back_populates="evaluations",
        foreign_keys=[team_id, hackathon_id],
        primaryjoin="and_(Evaluation.team_id == Team.id, Evaluation.hackathon_id == Team.hackathon_id)"
    )
    items = relationship("EvaluationItem", back_populates="evaluation", cascade="all, delete-orphan")
    assignment = relationship(
        "ExpertTeamAssignment", 
        back_populates="evaluation",
        foreign_keys="[Evaluation.hackathon_id, Evaluation.expert_user_id, Evaluation.team_id]",
        primaryjoin="and_(ExpertTeamAssignment.hackathon_id == Evaluation.hackathon_id, "
                   "ExpertTeamAssignment.expert_user_id == Evaluation.expert_user_id, "
                   "ExpertTeamAssignment.team_id == Evaluation.team_id)",
        viewonly=True
    )
    
    __table_args__ = (
        ForeignKeyConstraint(
            ['team_id', 'hackathon_id'],
            ['teams.id', 'teams.hackathon_id'],
            name='evaluations_team_fk',
            ondelete='CASCADE'
        ),
        ForeignKeyConstraint(
            ['hackathon_id', 'expert_user_id', 'team_id'],
            ['expert_team_assignments.hackathon_id', 'expert_team_assignments.expert_user_id', 'expert_team_assignments.team_id'],
            name='evaluations_assignment_fk',
            ondelete='RESTRICT'
        ),
        UniqueConstraint('hackathon_id', 'expert_user_id', 'team_id', name='evaluations_uniq'),
        CheckConstraint(
            "(status = 'draft' AND submitted_at IS NULL) OR (status = 'submitted' AND submitted_at IS NOT NULL)",
            name="evaluations_status_chk"
        ),
    )