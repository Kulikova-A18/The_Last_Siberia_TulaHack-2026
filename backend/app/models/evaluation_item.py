# backend/app/models/evaluation_item.py
from sqlalchemy import Column, Numeric, String, ForeignKey, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.models.base import Base, IDMixin, TimestampMixin


class EvaluationItem(Base, IDMixin, TimestampMixin):
    __tablename__ = "evaluation_items"
    
    evaluation_id = Column(UUID(as_uuid=True), ForeignKey("evaluations.id", ondelete="CASCADE"), nullable=False)
    criterion_id = Column(UUID(as_uuid=True), ForeignKey("criteria.id", ondelete="RESTRICT"), nullable=False)
    
    raw_score = Column(Numeric(6, 2), nullable=False)
    comment = Column(String)
    
    # Relationships
    evaluation = relationship("Evaluation", back_populates="items")
    criterion = relationship("Criterion", back_populates="evaluation_items")
    
    __table_args__ = (
        CheckConstraint("raw_score >= 0", name="evaluation_items_raw_score_chk"),
    )