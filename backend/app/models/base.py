# backend/app/models/base.py
from sqlalchemy.orm import declarative_base, declared_attr
from sqlalchemy import Column, DateTime, func, String
from uuid import uuid4, UUID
from sqlalchemy.dialects.postgresql import UUID as PGUUID

class BaseModel:
    @declared_attr
    def __tablename__(cls):
        return cls.__name__.lower()

    id = Column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

Base = declarative_base(cls=BaseModel)