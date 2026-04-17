# backend/app/models/team.py
from sqlalchemy import Column, String, ForeignKey, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID, CITEXT
from sqlalchemy.orm import relationship
from app.models.base import Base

class Team(Base):
    __tablename__ = "teams"
    
    hackathon_id = Column(UUID(as_uuid=True), ForeignKey("hackathons.id", ondelete="CASCADE"), nullable=False)
    
    name = Column(String(150), nullable=False)
    captain_name = Column(String(150), nullable=False)
    contact_email = Column(CITEXT)
    contact_phone = Column(String(32))
    project_title = Column(String(200), nullable=False)
    description = Column(String)
    
    # Relationships
    hackathon = relationship("Hackathon", back_populates="teams")
    account_user = relationship("User", back_populates="team", uselist=False)
    members = relationship("TeamMember", back_populates="team", cascade="all, delete-orphan")
    expert_assignments = relationship("ExpertTeamAssignment", back_populates="team", cascade="all, delete-orphan")
    evaluations = relationship("Evaluation", back_populates="team", cascade="all, delete-orphan")
    team_result = relationship("TeamResult", back_populates="team", uselist=False, cascade="all, delete-orphan")
    
    __table_args__ = (
        CheckConstraint("hackathon_id IS NOT NULL", name="teams_hackathon_id_not_null"),
    )