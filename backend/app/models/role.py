# backend/app/models/role.py
from sqlalchemy import Column, String, Table, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.models.base import Base, IDMixin  # убрали TimestampMixin

# Association table
role_permissions = Table(
    "role_permissions",
    Base.metadata,
    Column("role_id", UUID(as_uuid=True), ForeignKey("roles.id", ondelete="CASCADE"), primary_key=True),
    Column("permission_id", UUID(as_uuid=True), ForeignKey("permissions.id", ondelete="CASCADE"), primary_key=True),
)

class Role(Base, IDMixin):  # убрали TimestampMixin
    __tablename__ = "roles"
    
    code = Column(String(50), unique=True, nullable=False)
    name = Column(String(100), unique=True, nullable=False)
    created_at = Column(String)  # заглушка, если нужно
    
    # Relationships
    users = relationship("User", back_populates="role")
    permissions = relationship("Permission", secondary=role_permissions, back_populates="roles")

class Permission(Base, IDMixin):  # убрали TimestampMixin
    __tablename__ = "permissions"
    
    code = Column(String(100), unique=True, nullable=False)
    name = Column(String(150), nullable=False)
    description = Column(String(255))
    created_at = Column(String)  # заглушка
    
    # Relationships
    roles = relationship("Role", secondary=role_permissions, back_populates="permissions")