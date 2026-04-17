# backend/app/schemas/__init__.py
from app.schemas.auth import LoginRequest, TokenResponse, UserInfo, ChangePasswordRequest, RefreshTokenRequest
from app.schemas.user import UserCreate, UserUpdate, UserResponse, UserListResponse, ResetPasswordRequest
from app.schemas.role import RoleResponse, PermissionResponse
from app.schemas.hackathon import HackathonCreate, HackathonUpdate, HackathonResponse
from app.schemas.team import (
    TeamCreate, TeamUpdate, TeamResponse, TeamListResponse, TeamDetailResponse,
    TeamMemberCreate, TeamMemberUpdate, TeamMemberResponse, TeamAccount
)
from app.schemas.criterion import (
    CriterionCreate, CriterionUpdate, CriterionResponse, 
    CriteriaListResponse, CriteriaReorderRequest, CriteriaReorderItem
)
from app.schemas.assignment import AssignmentCreate, AssignmentBulkCreate, AssignmentBulkItem, AssignmentResponse
from app.schemas.evaluation import (
    EvaluationDraftRequest, EvaluationSubmitRequest, EvaluationItemRequest,
    EvaluationResponse, EvaluationItemResponse, MyEvaluationResponse, 
    AssignedTeamResponse, AssignedTeamListResponse
)
from app.schemas.result import (
    LeaderboardResponse, LeaderboardItem, TeamResultDetailResponse, 
    WinnersResponse, WinnersItem, CriterionBreakdown
)
from app.schemas.deadline import (
    DeadlineCreate, DeadlineUpdate, DeadlineResponse, TimerResponse, NextDeadlineResponse
)
from app.schemas.public import (
    PublicLeaderboardResponse, PublicLeaderboardItem, PublicTimerResponse, 
    PublicWinnersResponse, PublicHackathonResponse
)
from app.schemas.dashboard import (
    AdminDashboardResponse, ExpertDashboardResponse, TeamDashboardResponse, 
    ExpertsProgressItem, NextDeadlineItem, LeaderboardTopItem
)
from app.schemas.audit import AuditLogResponse, AuditLogListResponse

__all__ = [
    # Auth
    "LoginRequest", "TokenResponse", "UserInfo", "ChangePasswordRequest", "RefreshTokenRequest",
    # User
    "UserCreate", "UserUpdate", "UserResponse", "UserListResponse", "ResetPasswordRequest",
    # Role
    "RoleResponse", "PermissionResponse",
    # Hackathon
    "HackathonCreate", "HackathonUpdate", "HackathonResponse",
    # Team
    "TeamCreate", "TeamUpdate", "TeamResponse", "TeamListResponse", "TeamDetailResponse",
    "TeamMemberCreate", "TeamMemberUpdate", "TeamMemberResponse", "TeamAccount",
    # Criterion
    "CriterionCreate", "CriterionUpdate", "CriterionResponse", "CriteriaListResponse",
    "CriteriaReorderRequest", "CriteriaReorderItem",
    # Assignment
    "AssignmentCreate", "AssignmentBulkCreate", "AssignmentBulkItem", "AssignmentResponse",
    # Evaluation
    "EvaluationDraftRequest", "EvaluationSubmitRequest", "EvaluationItemRequest",
    "EvaluationResponse", "EvaluationItemResponse", "MyEvaluationResponse",
    "AssignedTeamResponse", "AssignedTeamListResponse",
    # Result
    "LeaderboardResponse", "LeaderboardItem", "TeamResultDetailResponse",
    "WinnersResponse", "WinnersItem", "CriterionBreakdown",
    # Deadline
    "DeadlineCreate", "DeadlineUpdate", "DeadlineResponse", "TimerResponse", "NextDeadlineResponse",
    # Public
    "PublicLeaderboardResponse", "PublicLeaderboardItem", "PublicTimerResponse",
    "PublicWinnersResponse", "PublicHackathonResponse",
    # Dashboard
    "AdminDashboardResponse", "ExpertDashboardResponse", "TeamDashboardResponse",
    "ExpertsProgressItem", "NextDeadlineItem", "LeaderboardTopItem",
    # Audit
    "AuditLogResponse", "AuditLogListResponse"
]