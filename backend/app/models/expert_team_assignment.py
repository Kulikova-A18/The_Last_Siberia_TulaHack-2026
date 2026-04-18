# backend/app/models/expert_team_assignment.py
from sqlalchemy import Column, ForeignKey, DateTime, ForeignKeyConstraint, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.models.base import Base

class ExpertTeamAssignment(Base):
    __tablename__ = "expert_team_assignments"
    
    hackathon_id = Column(UUID(as_uuid=True), ForeignKey("hackathons.id", ondelete="CASCADE"), nullable=False)
    expert_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    team_id = Column(UUID(as_uuid=True), nullable=False)
    assigned_at = Column(DateTime(timezone=True), server_default="now()", nullable=False)
    
    # Relationships
    hackathon = relationship("Hackathon", back_populates="expert_assignments")
    expert = relationship("User", foreign_keys=[expert_user_id], back_populates="expert_assignments")
    team = relationship(
        "Team", 
        back_populates="expert_assignments",
        foreign_keys=[team_id, hackathon_id],
        primaryjoin="and_(ExpertTeamAssignment.team_id == Team.id, ExpertTeamAssignment.hackathon_id == Team.hackathon_id)"
    )
    evaluation = relationship(
        "Evaluation", 
        back_populates="assignment", 
        uselist=False,
        foreign_keys="[Evaluation.hackathon_id, Evaluation.expert_user_id, Evaluation.team_id]",
        primaryjoin="and_(ExpertTeamAssignment.hackathon_id == Evaluation.hackathon_id, "
                   "ExpertTeamAssignment.expert_user_id == Evaluation.expert_user_id, "
                   "ExpertTeamAssignment.team_id == Evaluation.team_id)"
    )
    
    __table_args__ = (
        ForeignKeyConstraint(
            ['team_id', 'hackathon_id'],
            ['teams.id', 'teams.hackathon_id'],
            name='assignments_team_fk',
            ondelete='CASCADE'
        ),
        UniqueConstraint('hackathon_id', 'expert_user_id', 'team_id', name='assignments_uniq'),
    )