from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging

from app.api.v1 import (
    auth, users, roles, hackathons, teams, criteria,
    assignments, evaluations, results, deadlines, public, audit_logs
)
from app.core.database import engine
from app.models.base import Base
from app.core.config import settings
from app.websocket import leaderboard_ws

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting up...")
    async with engine.begin() as conn:
        # Import all models before creating tables
        from app.models import (
            User, Role, Permission, RefreshToken,
            Hackathon, Team, TeamMember, Criterion, ExpertTeamAssignment,
            Evaluation, EvaluationItem, Deadline, TeamResult, TeamResultItem, AuditLog
        )
        await conn.run_sync(Base.metadata.create_all)
    logger.info("Database tables created/verified")
    yield
    # Shutdown
    logger.info("Shutting down...")
    await engine.dispose()

app = FastAPI(
    title="HackRank API",
    description="API for hackathon evaluation automation",
    version="1.0.0",
    lifespan=lifespan
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API Routers
api_prefix = "/api/v1"

app.include_router(auth.router, prefix=api_prefix, tags=["Auth"])
app.include_router(users.router, prefix=api_prefix, tags=["Users"])
app.include_router(roles.router, prefix=api_prefix, tags=["Roles"])
app.include_router(hackathons.router, prefix=api_prefix, tags=["Hackathons"])
app.include_router(teams.router, prefix=api_prefix, tags=["Teams"])
app.include_router(criteria.router, prefix=api_prefix, tags=["Criteria"])
app.include_router(assignments.router, prefix=api_prefix, tags=["Assignments"])
app.include_router(evaluations.router, prefix=api_prefix, tags=["Evaluations"])
app.include_router(results.router, prefix=api_prefix, tags=["Results"])
app.include_router(deadlines.router, prefix=api_prefix, tags=["Deadlines"])
app.include_router(public.router, prefix=api_prefix, tags=["Public"])
app.include_router(audit_logs.router, prefix=api_prefix, tags=["Audit"])

# WebSocket
app.include_router(leaderboard_ws.router, prefix=f"{api_prefix}/ws", tags=["WebSocket"])

@app.get("/health")
async def health_check():
    return {"status": "ok"}