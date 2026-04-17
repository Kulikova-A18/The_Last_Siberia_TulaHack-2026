# backend/app/models/deadline.py
from sqlalchemy import Column, String, DateTime, Integer, ForeignKey, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy import Enum as PgEnum
from sqlalchemy.orm import relationship
from enum import Enum
from app.models.base import Base

class DeadlineKind(str, Enum):
    REGISTRATION = "registration"
    DEVELOPMENT = "development"
    PITCH = "pitch"
    EVALUATION = "evaluation"
    CUSTOM = "custom"

class Deadline(Base):
    __tablename__ = "deadlines"
    
    hackathon_id = Column(UUID(as_uuid=True), ForeignKey("hackathons.id", ondelete="CASCADE"), nullable=False)
    
    kind = Column(PgEnum(DeadlineKind), default=DeadlineKind.CUSTOM, nullable=False)
    title = Column(String(150), nullable=False)
    description = Column(String)
    deadline_at = Column(DateTime, nullable=False)
    notify_before_minutes = Column(Integer, default=0, nullable=False)
    
    # Relationships
    hackathon = relationship("Hackathon", back_populates="deadlines")
    
    __table_args__ = (
        CheckConstraint("notify_before_minutes >= 0", name="deadlines_notify_before_chk"),
    )