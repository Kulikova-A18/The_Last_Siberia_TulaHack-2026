# backend/tests/test_scoring_service.py
import pytest
from decimal import Decimal
from typing import List, Dict
from uuid import uuid4

from app.services.scoring_service import ScoringService


class MockCriterion:
    """Mock criterion for testing"""
    def __init__(self, id, max_score, weight_percent):
        self.id = id
        self.max_score = max_score
        self.weight_percent = weight_percent


class MockEvaluationItem:
    """Mock evaluation item for testing"""
    def __init__(self, criterion_id, raw_score):
        self.criterion_id = criterion_id
        self.raw_score = raw_score


class TestNormalization:
    """Tests for score normalization"""
    
    def test_normalize_perfect_score(self):
        """Test normalizing perfect score"""
        normalized = ScoringService.normalize_score(10, 10)
        assert normalized == 1.0
    
    def test_normalize_half_score(self):
        """Test normalizing half score"""
        normalized = ScoringService.normalize_score(5, 10)
        assert normalized == 0.5
    
    def test_normalize_zero_score(self):
        """Test normalizing zero score"""
        normalized = ScoringService.normalize_score(0, 10)
        assert normalized == 0.0
    
    def test_normalize_with_different_max_scores(self):
        """Test normalization with different max scores"""
        assert ScoringService.normalize_score(8, 10) == 0.8
        assert ScoringService.normalize_score(16, 20) == 0.8
        assert ScoringService.normalize_score(4, 5) == 0.8
    
    def test_normalize_float_scores(self):
        """Test normalization with float scores"""
        normalized = ScoringService.normalize_score(7.5, 10)
        assert normalized == 0.75
    
    def test_normalize_raises_on_zero_max_score(self):
        """Test that normalization raises error on zero max score"""
        with pytest.raises(ValueError, match="max_score must be greater than 0"):
            ScoringService.normalize_score(5, 0)
    
    def test_normalize_raises_on_negative_raw_score(self):
        """Test that normalization raises error on negative raw score"""
        with pytest.raises(ValueError, match="raw_score cannot be negative"):
            ScoringService.normalize_score(-1, 10)


class TestWeightedScore:
    """Tests for weighted score calculation"""
    
    def test_calculate_weighted_score(self):
        """Test calculating weighted score"""
        weighted = ScoringService.calculate_weighted_score(0.8, 25)
        assert weighted == 20.0
    
    def test_calculate_weighted_score_with_perfect_normalized(self):
        """Test weighted score with perfect normalized score"""
        weighted = ScoringService.calculate_weighted_score(1.0, 30)
        assert weighted == 30.0
    
    def test_calculate_weighted_score_with_zero_normalized(self):
        """Test weighted score with zero normalized score"""
        weighted = ScoringService.calculate_weighted_score(0.0, 25)
        assert weighted == 0.0
    
    def test_calculate_weighted_score_with_float_weight(self):
        """Test weighted score with float weight"""
        weighted = ScoringService.calculate_weighted_score(0.75, 33.33)
        assert round(weighted, 2) == 24.9975
    
    def test_calculate_weighted_score_raises_on_negative_weight(self):
        """Test that weighted score raises error on negative weight"""
        with pytest.raises(ValueError, match="weight_percent cannot be negative"):
            ScoringService.calculate_weighted_score(0.8, -10)
    
    def test_calculate_weighted_score_raises_on_weight_over_100(self):
        """Test that weighted score raises error on weight over 100"""
        with pytest.raises(ValueError, match="weight_percent cannot exceed 100"):
            ScoringService.calculate_weighted_score(0.8, 150)


class TestAverageCalculation:
    """Tests for average score calculation"""
    
    def test_average_of_multiple_scores(self):
        """Test calculating average of multiple scores"""
        scores = [8.0, 7.0, 9.0]
        avg = ScoringService.calculate_average(scores)
        assert avg == 8.0
    
    def test_average_of_single_score(self):
        """Test average of single score"""
        avg = ScoringService.calculate_average([7.5])
        assert avg == 7.5
    
    def test_average_of_empty_list(self):
        """Test average of empty list"""
        avg = ScoringService.calculate_average([])
        assert avg == 0.0
    
    def test_average_with_floats(self):
        """Test average with float values"""
        scores = [8.3, 7.7, 9.1]
        avg = ScoringService.calculate_average(scores)
        assert round(avg, 2) == 8.37
    
    def test_average_with_decimal_values(self):
        """Test average with decimal values"""
        scores = [Decimal('8.5'), Decimal('7.5'), Decimal('9.0')]
        avg = ScoringService.calculate_average(scores)
        assert avg == 8.333333333333334


class TestFinalScoreCalculation:
    """Tests for final score calculation"""
    
    def test_calculate_final_score_single_criterion(self):
        """Test final score with single criterion"""
        criteria = [
            MockCriterion(id=uuid4(), max_score=10, weight_percent=100)
        ]
        evaluations = [
            [MockEvaluationItem(criteria[0].id, 8)]
        ]
        
        final_score = ScoringService.calculate_final_score(criteria, evaluations)
        assert final_score == 80.0
    
    def test_calculate_final_score_multiple_criteria_single_expert(self):
        """Test final score with multiple criteria and single expert"""
        crit1 = MockCriterion(id=uuid4(), max_score=10, weight_percent=40)
        crit2 = MockCriterion(id=uuid4(), max_score=20, weight_percent=60)
        criteria = [crit1, crit2]
        
        evaluations = [
            [
                MockEvaluationItem(crit1.id, 8),
                MockEvaluationItem(crit2.id, 16)
            ]
        ]
        
        final_score = ScoringService.calculate_final_score(criteria, evaluations)
        # 8/10=0.8*40=32, 16/20=0.8*60=48, total=80
        assert final_score == 80.0
    
    def test_calculate_final_score_multiple_experts(self):
        """Test final score with multiple experts"""
        crit = MockCriterion(id=uuid4(), max_score=10, weight_percent=100)
        criteria = [crit]
        
        evaluations = [
            [MockEvaluationItem(crit.id, 8)],   # Expert 1
            [MockEvaluationItem(crit.id, 9)],   # Expert 2
            [MockEvaluationItem(crit.id, 7)]    # Expert 3
        ]
        
        final_score = ScoringService.calculate_final_score(criteria, evaluations)
        # Average raw = 8, normalized = 0.8, weighted = 80
        assert final_score == 80.0
    
    def test_calculate_final_score_with_missing_evaluations(self):
        """Test final score with missing evaluations for some criteria"""
        crit1 = MockCriterion(id=uuid4(), max_score=10, weight_percent=50)
        crit2 = MockCriterion(id=uuid4(), max_score=10, weight_percent=50)
        criteria = [crit1, crit2]
        
        evaluations = [
            [MockEvaluationItem(crit1.id, 8)]  # Missing crit2
        ]
        
        final_score = ScoringService.calculate_final_score(criteria, evaluations)
        # Only crit1 contributes: 8/10=0.8*50=40
        assert final_score == 40.0
    
    def test_calculate_final_score_empty_evaluations(self):
        """Test final score with empty evaluations"""
        criteria = [MockCriterion(id=uuid4(), max_score=10, weight_percent=100)]
        final_score = ScoringService.calculate_final_score(criteria, [])
        assert final_score == 0.0
    
    def test_calculate_final_score_raises_on_weight_sum_not_100(self):
        """Test that final score raises error if weights don't sum to 100"""
        crit1 = MockCriterion(id=uuid4(), max_score=10, weight_percent=40)
        crit2 = MockCriterion(id=uuid4(), max_score=10, weight_percent=40)
        criteria = [crit1, crit2]
        
        with pytest.raises(ValueError, match="Total weight must be 100%"):
            ScoringService.calculate_final_score(criteria, [])


class TestTeamResultCalculation:
    """Tests for team result calculation"""
    
    def test_calculate_team_result_basic(self):
        """Test basic team result calculation"""
        crit = MockCriterion(id=uuid4(), max_score=10, weight_percent=100)
        criteria = [crit]
        
        evaluations = [
            [MockEvaluationItem(crit.id, 8)]
        ]
        
        result = ScoringService.calculate_team_result(criteria, evaluations)
        
        assert result["final_score"] == 80.0
        assert result["evaluated_by_count"] == 1
        assert len(result["criterion_results"]) == 1
        
        criterion_result = result["criterion_results"][0]
        assert criterion_result["avg_raw_score"] == 8.0
        assert criterion_result["avg_normalized_score"] == 0.8
        assert criterion_result["weighted_score"] == 80.0
    
    def test_calculate_team_result_with_multiple_experts(self):
        """Test team result with multiple experts"""
        crit = MockCriterion(id=uuid4(), max_score=10, weight_percent=100)
        criteria = [crit]
        
        evaluations = [
            [MockEvaluationItem(crit.id, 7)],
            [MockEvaluationItem(crit.id, 8)],
            [MockEvaluationItem(crit.id, 9)]
        ]
        
        result = ScoringService.calculate_team_result(criteria, evaluations)
        
        assert result["final_score"] == 80.0  # Average 8/10
        assert result["evaluated_by_count"] == 3
        assert result["criterion_results"][0]["avg_raw_score"] == 8.0
    
    def test_calculate_team_result_with_multiple_criteria(self):
        """Test team result with multiple criteria"""
        crit1 = MockCriterion(id=uuid4(), max_score=10, weight_percent=40)
        crit2 = MockCriterion(id=uuid4(), max_score=20, weight_percent=60)
        criteria = [crit1, crit2]
        
        evaluations = [
            [
                MockEvaluationItem(crit1.id, 8),
                MockEvaluationItem(crit2.id, 16)
            ],
            [
                MockEvaluationItem(crit1.id, 9),
                MockEvaluationItem(crit2.id, 18)
            ]
        ]
        
        result = ScoringService.calculate_team_result(criteria, evaluations)
        
        # crit1: avg raw = 8.5, normalized = 0.85, weighted = 34
        # crit2: avg raw = 17, normalized = 0.85, weighted = 51
        # total = 85
        assert round(result["final_score"], 1) == 85.0
        assert result["evaluated_by_count"] == 2
    
    def test_calculate_team_result_with_zero_evaluations(self):
        """Test team result with zero evaluations"""
        crit = MockCriterion(id=uuid4(), max_score=10, weight_percent=100)
        criteria = [crit]
        
        result = ScoringService.calculate_team_result(criteria, [])
        
        assert result["final_score"] == 0.0
        assert result["evaluated_by_count"] == 0
        assert result["criterion_results"][0]["avg_raw_score"] == 0.0


class TestLeaderboardGeneration:
    """Tests for leaderboard generation"""
    
    def test_generate_leaderboard_simple(self):
        """Test generating leaderboard with simple data"""
        team_results = [
            {"team_id": uuid4(), "team_name": "Team A", "final_score": 85.0},
            {"team_id": uuid4(), "team_name": "Team B", "final_score": 92.0},
            {"team_id": uuid4(), "team_name": "Team C", "final_score": 78.0},
        ]
        
        leaderboard = ScoringService.generate_leaderboard(team_results)
        
        assert leaderboard[0]["place"] == 1
        assert leaderboard[0]["team_name"] == "Team B"
        assert leaderboard[0]["final_score"] == 92.0
        
        assert leaderboard[1]["place"] == 2
        assert leaderboard[1]["team_name"] == "Team A"
        
        assert leaderboard[2]["place"] == 3
        assert leaderboard[2]["team_name"] == "Team C"
    
    def test_generate_leaderboard_with_ties(self):
        """Test leaderboard generation with tied scores"""
        team_results = [
            {"team_id": uuid4(), "team_name": "Team A", "final_score": 85.0},
            {"team_id": uuid4(), "team_name": "Team B", "final_score": 85.0},
            {"team_id": uuid4(), "team_name": "Team C", "final_score": 78.0},
        ]
        
        leaderboard = ScoringService.generate_leaderboard(team_results)
        
        # Teams with same score get same place
        assert leaderboard[0]["place"] == 1
        assert leaderboard[1]["place"] == 1
        assert leaderboard[2]["place"] == 3
    
    def test_generate_leaderboard_empty(self):
        """Test leaderboard generation with empty data"""
        leaderboard = ScoringService.generate_leaderboard([])
        assert leaderboard == []
    
    def test_generate_leaderboard_single_team(self):
        """Test leaderboard generation with single team"""
        team_results = [
            {"team_id": uuid4(), "team_name": "Team A", "final_score": 100.0}
        ]
        
        leaderboard = ScoringService.generate_leaderboard(team_results)
        
        assert leaderboard[0]["place"] == 1
        assert leaderboard[0]["team_name"] == "Team A"
    
    def test_generate_leaderboard_preserves_original_data(self):
        """Test that leaderboard generation preserves all original data"""
        team_results = [
            {"team_id": uuid4(), "team_name": "Team A", "final_score": 85.0, "extra_field": "value"}
        ]
        
        leaderboard = ScoringService.generate_leaderboard(team_results)
        
        assert leaderboard[0]["extra_field"] == "value"
        assert leaderboard[0]["team_name"] == "Team A"
        assert leaderboard[0]["final_score"] == 85.0