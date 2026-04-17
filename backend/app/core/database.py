# backend/app/core/database.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from sqlalchemy import MetaData
from app.core.config import settings

# Convention for naming constraints
convention = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s"
}

metadata = MetaData(naming_convention=convention)

# Create async engine
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20
)

# Create async session factory
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False
)

# Base class for models
Base = declarative_base(metadata=metadata)

async def get_db():
    """Dependency for getting database session"""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()

async def init_db():
    """Initialize database (create tables if not exist)"""
    async with engine.begin() as conn:
        # Import all models to ensure they are registered
        from app.models import (
            User, Role, Permission, role_permissions, RefreshToken,
            Hackathon, Team, TeamMember, Criterion, ExpertTeamAssignment,
            Evaluation, EvaluationItem, Deadline, TeamResult, TeamResultItem, AuditLog
        )
        # These imports are used by SQLAlchemy metadata
        _ = (User, Role, Permission, role_permissions, RefreshToken,
             Hackathon, Team, TeamMember, Criterion, ExpertTeamAssignment,
             Evaluation, EvaluationItem, Deadline, TeamResult, TeamResultItem, AuditLog)
        await conn.run_sync(Base.metadata.create_all)