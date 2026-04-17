# backend/app/services/scoring_service.py
from decimal import Decimal
from typing import List, Dict, Any
from uuid import UUID


class ScoringService:
    """Service for calculating scores and leaderboards"""
    
    @staticmethod
    def normalize_score(raw_score: float, max_score: float) -> float:
        """Normalize a score to a 0-1 range"""
        if max_score <= 0:
            raise ValueError("max_score must be greater than 0")
        if raw_score < 0:
            raise ValueError("raw_score cannot be negative")
        return raw_score / max_score
    
    @staticmethod
    def calculate_weighted_score(normalized_score: float, weight_percent: float) -> float:
        """Calculate weighted score contribution"""
        if weight_percent < 0:
            raise ValueError("weight_percent cannot be negative")
        if weight_percent > 100:
            raise ValueError("weight_percent cannot exceed 100")
        return normalized_score * weight_percent
    
    @staticmethod
    def calculate_average(scores: List[float]) -> float:
        """Calculate average of scores"""
        if not scores:
            return 0.0
        return sum(scores) / len(scores)
    
    @staticmethod
    def calculate_final_score(criteria: List, evaluations: List) -> float:
        """Calculate final score for a team"""
        if not criteria:
            return 0.0
        
        # Validate total weight is 100
        total_weight = sum(c.weight_percent for c in criteria)
        if abs(total_weight - 100) > 0.01:
            raise ValueError(f"Total weight must be 100%. Current sum: {total_weight}")
        
        if not evaluations:
            return 0.0
        
        # Calculate average scores per criterion
        criterion_scores = {}
        for criterion in criteria:
            scores = []
            for evaluation in evaluations:
                for item in evaluation:
                    if item.criterion_id == criterion.id:
                        scores.append(float(item.raw_score))
            if scores:
                avg_raw = ScoringService.calculate_average(scores)
                normalized = ScoringService.normalize_score(avg_raw, float(criterion.max_score))
                criterion_scores[criterion.id] = normalized
        
        # Calculate weighted sum
        final_score = 0.0
        for criterion in criteria:
            if criterion.id in criterion_scores:
                final_score += ScoringService.calculate_weighted_score(
                    criterion_scores[criterion.id],
                    float(criterion.weight_percent)
                )
        
        return final_score
    
    @staticmethod
    def calculate_team_result(criteria: List, evaluations: List) -> Dict[str, Any]:
        """Calculate detailed team result"""
        if not criteria:
            return {
                "final_score": 0.0,
                "evaluated_by_count": 0,
                "criterion_results": []
            }
        
        # Validate total weight is 100
        total_weight = sum(c.weight_percent for c in criteria)
        if abs(total_weight - 100) > 0.01:
            raise ValueError(f"Total weight must be 100%. Current sum: {total_weight}")
        
        evaluated_by_count = len(evaluations)
        criterion_results = []
        
        for criterion in criteria:
            scores = []
            for evaluation in evaluations:
                for item in evaluation:
                    if item.criterion_id == criterion.id:
                        scores.append(float(item.raw_score))
            
            if scores:
                avg_raw = ScoringService.calculate_average(scores)
                normalized = ScoringService.normalize_score(avg_raw, float(criterion.max_score))
                weighted = ScoringService.calculate_weighted_score(normalized, float(criterion.weight_percent))
            else:
                avg_raw = 0.0
                normalized = 0.0
                weighted = 0.0
            
            criterion_results.append({
                "criterion_id": criterion.id,
                "avg_raw_score": avg_raw,
                "avg_normalized_score": normalized,
                "weighted_score": weighted
            })
        
        final_score = sum(r["weighted_score"] for r in criterion_results)
        
        return {
            "final_score": final_score,
            "evaluated_by_count": evaluated_by_count,
            "criterion_results": criterion_results
        }
    
    @staticmethod
    def generate_leaderboard(team_results: List[Dict]) -> List[Dict]:
        """Generate leaderboard from team results"""
        if not team_results:
            return []
        
        # Sort by final score descending
        sorted_results = sorted(team_results, key=lambda x: x.get("final_score", 0), reverse=True)
        
        # Assign places (handling ties)
        leaderboard = []
        current_place = 1
        prev_score = None
        
        for i, result in enumerate(sorted_results):
            if prev_score is not None and result["final_score"] < prev_score:
                current_place = i + 1
            
            leaderboard.append({
                **result,
                "place": current_place
            })
            prev_score = result["final_score"]
        
        return leaderboard