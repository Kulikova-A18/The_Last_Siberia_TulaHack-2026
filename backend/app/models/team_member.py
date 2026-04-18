# backend/app/models/team_member.py
from sqlalchemy import Column, String, Boolean, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, CITEXT
from sqlalchemy.orm import relationship
from app.models.base import Base, IDMixin, TimestampMixin


class TeamMember(Base, IDMixin, TimestampMixin):
    __tablename__ = "team_members"
    
    team_id = Column(UUID(as_uuid=True), ForeignKey("teams.id", ondelete="CASCADE"), nullable=False)
    
    full_name = Column(String(200), nullable=False)
    email = Column(CITEXT)
    phone = Column(String(32))
    organization = Column(String(200))
    is_captain = Column(Boolean, default=False)
    
    # Relationships
    team = relationship("Team", back_populates="members")