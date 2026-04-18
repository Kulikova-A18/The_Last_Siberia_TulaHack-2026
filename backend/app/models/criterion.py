# backend/app/models/criterion.py
from sqlalchemy import Column, String, Numeric, Integer, Boolean, ForeignKey, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.models.base import Base, IDMixin, TimestampMixin


class Criterion(Base, IDMixin, TimestampMixin):
    __tablename__ = "criteria"
    
    hackathon_id = Column(UUID(as_uuid=True), ForeignKey("hackathons.id", ondelete="CASCADE"), nullable=False)
    
    title = Column(String(150), nullable=False)
    description = Column(String)
    max_score = Column(Numeric(6, 2), nullable=False)
    weight_percent = Column(Numeric(5, 2), nullable=False)
    sort_order = Column(Integer, nullable=False)
    is_active = Column(Boolean, default=True)
    
    # Relationships
    hackathon = relationship("Hackathon", back_populates="criteria")
    evaluation_items = relationship("EvaluationItem", back_populates="criterion", cascade="all, delete-orphan")
    team_result_items = relationship("TeamResultItem", back_populates="criterion", cascade="all, delete-orphan")
    
    __table_args__ = (
        CheckConstraint("max_score > 0", name="criteria_max_score_chk"),
        CheckConstraint("weight_percent >= 0 AND weight_percent <= 100", name="criteria_weight_chk"),
        CheckConstraint("sort_order > 0", name="criteria_sort_order_chk"),
    )