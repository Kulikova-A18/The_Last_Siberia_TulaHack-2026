# backend/app/models/expert_team_assignment.py
from sqlalchemy import Column, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.models.base import Base

class ExpertTeamAssignment(Base):
    __tablename__ = "expert_team_assignments"
    
    hackathon_id = Column(UUID(as_uuid=True), ForeignKey("hackathons.id", ondelete="CASCADE"), nullable=False)
    expert_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    team_id = Column(UUID(as_uuid=True), nullable=False)
    assigned_at = Column(DateTime, server_default="now()", nullable=False)
    
    # Relationships
    hackathon = relationship("Hackathon", back_populates="expert_assignments")
    expert = relationship("User", foreign_keys=[expert_user_id], back_populates="expert_assignments")
    team = relationship("Team", back_populates="expert_assignments")
    evaluation = relationship("Evaluation", back_populates="assignment", uselist=False)