# backend/tests/test_validation.py
import pytest
from pydantic import ValidationError
from decimal import Decimal

from app.schemas.auth import LoginRequest, ChangePasswordRequest
from app.schemas.user import UserCreate, UserUpdate
from app.schemas.team import TeamCreate, TeamMemberCreate
from app.schemas.criterion import CriterionCreate, CriteriaReorderRequest
from app.schemas.evaluation import EvaluationDraftRequest, EvaluationItemRequest


class TestAuthSchemas:
    """Tests for authentication schemas"""
    
    def test_valid_login_request(self):
        """Test valid login request"""
        data = LoginRequest(login="testuser", password="password123")
        assert data.login == "testuser"
        assert data.password == "password123"
    
    def test_login_request_min_length(self):
        """Test login request with minimum length"""
        data = LoginRequest(login="abc", password="123456")
        assert data.login == "abc"
    
    def test_login_request_login_too_short(self):
        """Test login request with too short login"""
        with pytest.raises(ValidationError) as exc_info:
            LoginRequest(login="ab", password="123456")
        assert "ensure this value has at least 3 characters" in str(exc_info.value)
    
    def test_login_request_password_too_short(self):
        """Test login request with too short password"""
        with pytest.raises(ValidationError) as exc_info:
            LoginRequest(login="testuser", password="12345")
        assert "ensure this value has at least 6 characters" in str(exc_info.value)
    
    def test_change_password_request_valid(self):
        """Test valid change password request"""
        data = ChangePasswordRequest(old_password="old123", new_password="new123456")
        assert data.old_password == "old123"
        assert data.new_password == "new123456"
    
    def test_change_password_request_new_password_too_short(self):
        """Test change password with too short new password"""
        with pytest.raises(ValidationError) as exc_info:
            ChangePasswordRequest(old_password="old123", new_password="new12")
        assert "ensure this value has at least 6 characters" in str(exc_info.value)


class TestUserSchemas:
    """Tests for user schemas"""
    
    def test_valid_user_create(self):
        """Test valid user creation"""
        data = UserCreate(
            login="newuser",
            password="password123",
            full_name="New User",
            email="user@example.com",
            role_code="expert"
        )
        assert data.login == "newuser"
        assert data.role_code == "expert"
    
    def test_user_create_minimum_fields(self):
        """Test user creation with minimum required fields"""
        data = UserCreate(
            login="newuser",
            password="password123",
            full_name="New User",
            role_code="team"
        )
        assert data.email is None
    
    def test_user_create_invalid_email(self):
        """Test user creation with invalid email"""
        with pytest.raises(ValidationError):
            UserCreate(
                login="newuser",
                password="password123",
                full_name="New User",
                email="not-an-email",
                role_code="expert"
            )
    
    def test_valid_user_update(self):
        """Test valid user update"""
        data = UserUpdate(full_name="Updated Name", is_active=False)
        assert data.full_name == "Updated Name"
        assert data.is_active is False
    
    def test_user_update_empty(self):
        """Test empty user update"""
        data = UserUpdate()
        assert data.full_name is None
        assert data.email is None


class TestTeamSchemas:
    """Tests for team schemas"""
    
    def test_valid_team_create(self):
        """Test valid team creation"""
        data = TeamCreate(
            name="Team Alpha",
            captain_name="John Doe",
            project_title="Awesome Project",
            description="Project description",
            members=[
                TeamMemberCreate(
                    full_name="John Doe",
                    email="john@example.com",
                    is_captain=True
                )
            ]
        )
        assert data.name == "Team Alpha"
        assert len(data.members) == 1
        assert data.members[0].is_captain is True
    
    def test_team_create_without_members(self):
        """Test team creation without members"""
        data = TeamCreate(
            name="Team Alpha",
            captain_name="John Doe",
            project_title="Awesome Project"
        )
        assert data.members is None
    
    def test_team_create_invalid_email(self):
        """Test team creation with invalid email"""
        with pytest.raises(ValidationError):
            TeamMemberCreate(
                full_name="John Doe",
                email="invalid-email",
                is_captain=True
            )


class TestCriterionSchemas:
    """Tests for criterion schemas"""
    
    def test_valid_criterion_create(self):
        """Test valid criterion creation"""
        data = CriterionCreate(
            title="Innovation",
            description="Level of innovation",
            max_score=10.0,
            weight_percent=25.0,
            sort_order=1
        )
        assert data.title == "Innovation"
        assert data.max_score == 10.0
        assert data.weight_percent == 25.0
    
    def test_criterion_create_negative_max_score(self):
        """Test criterion creation with negative max score"""
        with pytest.raises(ValidationError):
            CriterionCreate(
                title="Innovation",
                max_score=-5.0,
                weight_percent=25.0,
                sort_order=1
            )
    
    def test_criterion_create_weight_out_of_range(self):
        """Test criterion creation with weight out of range"""
        with pytest.raises(ValidationError):
            CriterionCreate(
                title="Innovation",
                max_score=10.0,
                weight_percent=150.0,
                sort_order=1
            )
    
    def test_criterion_create_negative_weight(self):
        """Test criterion creation with negative weight"""
        with pytest.raises(ValidationError):
            CriterionCreate(
                title="Innovation",
                max_score=10.0,
                weight_percent=-10.0,
                sort_order=1
            )
    
    def test_valid_criteria_reorder(self):
        """Test valid criteria reorder request"""
        from uuid import uuid4
        data = CriteriaReorderRequest(
            items=[
                {"id": uuid4(), "sort_order": 1},
                {"id": uuid4(), "sort_order": 2}
            ]
        )
        assert len(data.items) == 2


class TestEvaluationSchemas:
    """Tests for evaluation schemas"""
    
    def test_valid_evaluation_item(self):
        """Test valid evaluation item"""
        from uuid import uuid4
        data = EvaluationItemRequest(
            criterion_id=uuid4(),
            raw_score=8.5,
            comment="Good work"
        )
        assert data.raw_score == 8.5
    
    def test_evaluation_item_negative_score(self):
        """Test evaluation item with negative score"""
        from uuid import uuid4
        with pytest.raises(ValidationError):
            EvaluationItemRequest(
                criterion_id=uuid4(),
                raw_score=-1.0
            )
    
    def test_valid_evaluation_draft(self):
        """Test valid evaluation draft request"""
        from uuid import uuid4
        data = EvaluationDraftRequest(
            items=[
                EvaluationItemRequest(criterion_id=uuid4(), raw_score=8.0)
            ],
            overall_comment="Great project!"
        )
        assert len(data.items) == 1
        assert data.overall_comment == "Great project!"
    
    def test_evaluation_draft_empty_items(self):
        """Test evaluation draft with empty items"""
        data = EvaluationDraftRequest(items=[])
        assert data.items == []
    
    def test_evaluation_draft_high_score(self):
        """Test evaluation draft with score higher than max (will be validated by service)"""
        from uuid import uuid4
        data = EvaluationItemRequest(
            criterion_id=uuid4(),
            raw_score=100.0
        )
        assert data.raw_score == 100.0  # Service will validate against max_score