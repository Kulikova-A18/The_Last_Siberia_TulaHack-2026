# backend/tests/test_scoring_unit.py
"""Unit tests for scoring service (without database)"""

import pytest
from uuid import uuid4
from decimal import Decimal
from app.services.scoring_service import ScoringService


class MockCriterion:
    def __init__(self, id, max_score, weight_percent):
        self.id = id
        self.max_score = max_score
        self.weight_percent = weight_percent


class MockEvaluationItem:
    def __init__(self, criterion_id, raw_score):
        self.criterion_id = criterion_id
        self.raw_score = raw_score


class TestNormalization:
    """Tests for score normalization"""
    
    def test_normalize_perfect_score(self):
        normalized = ScoringService.normalize_score(10, 10)
        assert normalized == 1.0
    
    def test_normalize_half_score(self):
        normalized = ScoringService.normalize_score(5, 10)
        assert normalized == 0.5
    
    def test_normalize_zero_score(self):
        normalized = ScoringService.normalize_score(0, 10)
        assert normalized == 0.0
    
    def test_normalize_with_different_max_scores(self):
        assert ScoringService.normalize_score(8, 10) == 0.8
        assert ScoringService.normalize_score(16, 20) == 0.8
        assert ScoringService.normalize_score(4, 5) == 0.8
    
    def test_normalize_float_scores(self):
        normalized = ScoringService.normalize_score(7.5, 10)
        assert normalized == 0.75
    
    def test_normalize_raises_on_zero_max_score(self):
        with pytest.raises(ValueError, match="max_score must be greater than 0"):
            ScoringService.normalize_score(5, 0)
    
    def test_normalize_raises_on_negative_raw_score(self):
        with pytest.raises(ValueError, match="raw_score cannot be negative"):
            ScoringService.normalize_score(-1, 10)


class TestWeightedScore:
    """Tests for weighted score calculation"""
    
    def test_calculate_weighted_score(self):
        weighted = ScoringService.calculate_weighted_score(0.8, 25)
        assert weighted == 20.0
    
    def test_calculate_weighted_score_with_perfect_normalized(self):
        weighted = ScoringService.calculate_weighted_score(1.0, 30)
        assert weighted == 30.0
    
    def test_calculate_weighted_score_with_zero_normalized(self):
        weighted = ScoringService.calculate_weighted_score(0.0, 25)
        assert weighted == 0.0
    
    def test_calculate_weighted_score_raises_on_negative_weight(self):
        with pytest.raises(ValueError, match="weight_percent cannot be negative"):
            ScoringService.calculate_weighted_score(0.8, -10)
    
    def test_calculate_weighted_score_raises_on_weight_over_100(self):
        with pytest.raises(ValueError, match="weight_percent cannot exceed 100"):
            ScoringService.calculate_weighted_score(0.8, 150)


class TestAverageCalculation:
    """Tests for average score calculation"""
    
    def test_average_of_multiple_scores(self):
        scores = [8.0, 7.0, 9.0]
        avg = ScoringService.calculate_average(scores)
        assert avg == 8.0
    
    def test_average_of_single_score(self):
        avg = ScoringService.calculate_average([7.5])
        assert avg == 7.5
    
    def test_average_of_empty_list(self):
        avg = ScoringService.calculate_average([])
        assert avg == 0.0
    
    def test_average_with_floats(self):
        scores = [8.3, 7.7, 9.1]
        avg = ScoringService.calculate_average(scores)
        assert round(avg, 2) == 8.37


class TestLeaderboardGeneration:
    """Tests for leaderboard generation"""
    
    def test_generate_leaderboard_simple(self):
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
        team_results = [
            {"team_id": uuid4(), "team_name": "Team A", "final_score": 85.0},
            {"team_id": uuid4(), "team_name": "Team B", "final_score": 85.0},
            {"team_id": uuid4(), "team_name": "Team C", "final_score": 78.0},
        ]
        
        leaderboard = ScoringService.generate_leaderboard(team_results)
        
        assert leaderboard[0]["place"] == 1
        assert leaderboard[1]["place"] == 1
        assert leaderboard[2]["place"] == 3
    
    def test_generate_leaderboard_empty(self):
        leaderboard = ScoringService.generate_leaderboard([])
        assert leaderboard == []
    
    def test_generate_leaderboard_single_team(self):
        team_results = [
            {"team_id": uuid4(), "team_name": "Team A", "final_score": 100.0}
        ]
        
        leaderboard = ScoringService.generate_leaderboard(team_results)
        
        assert leaderboard[0]["place"] == 1
        assert leaderboard[0]["team_name"] == "Team A"