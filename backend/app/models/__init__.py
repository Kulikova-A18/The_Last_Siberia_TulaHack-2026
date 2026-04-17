# backend/app/models/__init__.py
from app.models.base import Base
from app.models.user import User
from app.models.role import Role, Permission, role_permissions
from app.models.refresh_token import RefreshToken
from app.models.hackathon import Hackathon
from app.models.team import Team
from app.models.team_member import TeamMember
from app.models.criterion import Criterion
from app.models.expert_team_assignment import ExpertTeamAssignment
from app.models.evaluation import Evaluation
from app.models.evaluation_item import EvaluationItem
from app.models.deadline import Deadline
from app.models.team_result import TeamResult, TeamResultItem
from app.models.audit_log import AuditLog

__all__ = [
    "Base", "User", "Role", "Permission", "role_permissions", "RefreshToken",
    "Hackathon", "Team", "TeamMember", "Criterion", "ExpertTeamAssignment",
    "Evaluation", "EvaluationItem", "Deadline", "TeamResult", "TeamResultItem", "AuditLog"
]