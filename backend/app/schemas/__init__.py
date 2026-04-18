# backend/app/schemas/__init__.py
from app.schemas.auth import (
    LoginRequest, TokenResponse, RefreshTokenRequest, 
    ChangePasswordRequest, UserInfo
)
from app.schemas.user import (
    UserCreate, UserUpdate, UserResponse, UserListResponse,
    ResetPasswordRequest as UserResetPasswordRequest
)
from app.schemas.hackathon import (
    HackathonCreate, HackathonUpdate, HackathonResponse
)
from app.schemas.team import (
    TeamCreate, TeamUpdate, TeamResponse, TeamListResponse,
    TeamDetailResponse, TeamMemberCreate, TeamMemberUpdate,
    TeamMemberResponse, AssignedExpertInfo
)
from app.schemas.criterion import (
    CriterionCreate, CriterionUpdate, CriterionResponse,
    CriteriaListResponse, CriteriaReorderRequest
)
from app.schemas.assignment import (
    AssignmentCreate, AssignmentBulkCreate, AssignmentResponse
)
from app.schemas.evaluation import (
    EvaluationDraftRequest, EvaluationSubmitRequest,
    EvaluationResponse, MyEvaluationResponse,
    AssignedTeamResponse, AssignedTeamListResponse
)
from app.schemas.deadline import (
    DeadlineCreate, DeadlineUpdate, DeadlineResponse, TimerResponse
)
from app.schemas.result import (
    LeaderboardResponse, TeamResultDetailResponse, WinnersResponse
)
from app.schemas.public import (
    PublicHackathonResponse, PublicLeaderboardResponse,
    PublicTimerResponse, PublicWinnersResponse, PublicLeaderboardItem
)
from app.schemas.role import RoleResponse, PermissionResponse
from app.schemas.audit import AuditLogResponse, AuditLogListResponse

__all__ = [
    # Auth
    "LoginRequest", "TokenResponse", "RefreshTokenRequest",
    "ChangePasswordRequest", "UserInfo",
    # User
    "UserCreate", "UserUpdate", "UserResponse", "UserListResponse",
    "UserResetPasswordRequest",
    # Hackathon
    "HackathonCreate", "HackathonUpdate", "HackathonResponse",
    # Team
    "TeamCreate", "TeamUpdate", "TeamResponse", "TeamListResponse",
    "TeamDetailResponse", "TeamMemberCreate", "TeamMemberUpdate",
    "TeamMemberResponse", "AssignedExpertInfo",
    # Criterion
    "CriterionCreate", "CriterionUpdate", "CriterionResponse",
    "CriteriaListResponse", "CriteriaReorderRequest",
    # Assignment
    "AssignmentCreate", "AssignmentBulkCreate", "AssignmentResponse",
    # Evaluation
    "EvaluationDraftRequest", "EvaluationSubmitRequest",
    "EvaluationResponse", "MyEvaluationResponse",
    "AssignedTeamResponse", "AssignedTeamListResponse",
    # Deadline
    "DeadlineCreate", "DeadlineUpdate", "DeadlineResponse", "TimerResponse",
    # Result
    "LeaderboardResponse", "TeamResultDetailResponse", "WinnersResponse",
    # Public
    "PublicHackathonResponse", "PublicLeaderboardResponse",
    "PublicTimerResponse", "PublicWinnersResponse", "PublicLeaderboardItem",
    # Role
    "RoleResponse", "PermissionResponse",
    # Audit
    "AuditLogResponse", "AuditLogListResponse",
]
