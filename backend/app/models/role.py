# backend/app/models/role.py
from sqlalchemy import Column, String, Table, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.models.base import Base

# Association table for role_permissions
role_permissions = Table(
    "role_permissions",
    Base.metadata,
    Column("role_id", UUID(as_uuid=True), ForeignKey("roles.id", ondelete="CASCADE"), primary_key=True),
    Column("permission_id", UUID(as_uuid=True), ForeignKey("permissions.id", ondelete="CASCADE"), primary_key=True),
)

class Role(Base):
    __tablename__ = "roles"
    
    code = Column(String(50), unique=True, nullable=False)
    name = Column(String(100), unique=True, nullable=False)
    
    # Relationships
    users = relationship("User", back_populates="role")
    permissions = relationship("Permission", secondary=role_permissions, back_populates="roles")

class Permission(Base):
    __tablename__ = "permissions"
    
    code = Column(String(100), unique=True, nullable=False)
    name = Column(String(150), nullable=False)
    description = Column(String(255))
    
    # Relationships
    roles = relationship("Role", secondary=role_permissions, back_populates="permissions")