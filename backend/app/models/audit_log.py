# backend/app/models/audit_log.py
from sqlalchemy import Column, String, JSON, DateTime
from sqlalchemy.dialects.postgresql import UUID, INET
from sqlalchemy.orm import relationship
from app.models.base import Base
from uuid import uuid4

class AuditLog(Base):
    __tablename__ = "audit_logs"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    hackathon_id = Column(UUID(as_uuid=True), ForeignKey("hackathons.id", ondelete="CASCADE"), nullable=True)
    actor_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    
    action = Column(String(100), nullable=False)
    entity_type = Column(String(100), nullable=False)
    entity_id = Column(UUID(as_uuid=True), nullable=True)
    
    payload = Column(JSON, default={}, nullable=False)
    
    ip_address = Column(INET)
    user_agent = Column(String)
    
    created_at = Column(DateTime, server_default="now()", nullable=False)
    
    # Relationships
    hackathon = relationship("Hackathon", back_populates="audit_logs")
    actor = relationship("User", back_populates="audit_logs")