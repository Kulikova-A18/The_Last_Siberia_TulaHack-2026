# backend/app/api/v1/__init__.py
from app.api.v1 import (
    auth, users, roles, hackathons, teams, criteria,
    assignments, evaluations, results, deadlines, public, audit_logs
)

__all__ = [
    "auth",
    "users", 
    "roles",
    "hackathons",
    "teams",
    "criteria",
    "assignments",
    "evaluations",
    "results",
    "deadlines",
    "public",
    "audit_logs"
]