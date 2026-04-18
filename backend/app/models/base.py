# backend/app/models/base.py
from sqlalchemy.orm import declarative_base
from sqlalchemy import Column, DateTime, func
from uuid import uuid4
from sqlalchemy.dialects.postgresql import UUID as PGUUID

Base = declarative_base()

class TimestampMixin:
    id = Column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)