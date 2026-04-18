# backend/app/api/v1/evaluations.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Optional
from uuid import UUID
from datetime import datetime, timezone

from app.core.database import get_db
from app.dependencies.auth import get_current_user, expert_required, admin_required
from app.models.user import User
from app.models.team import Team
from app.models.evaluation import Evaluation, EvaluationStatus
from app.models.evaluation_item import EvaluationItem
from app.models.criterion import Criterion
from app.models.expert_team_assignment import ExpertTeamAssignment
from app.schemas.evaluation import (
    EvaluationDraftRequest, EvaluationSubmitRequest, EvaluationResponse,
    MyEvaluationResponse, AssignedTeamResponse, AssignedTeamListResponse,
    EvaluationItemResponse
)

router = APIRouter(prefix="/hackathons/{hackathon_id}", tags=["Evaluations"])

@router.get("/my/assigned-teams", response_model=AssignedTeamListResponse)
async def get_my_assigned_teams(
    hackathon_id: UUID,
    status: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(expert_required),
    db: AsyncSession = Depends(get_db)
):
    """Get teams assigned to current expert"""
    assignments_query = (
        select(ExpertTeamAssignment)
        .where(
            ExpertTeamAssignment.hackathon_id == hackathon_id,
            ExpertTeamAssignment.expert_user_id == current_user.id
        )
    )
    
    assignments_result = await db.execute(assignments_query)
    assignments = assignments_result.scalars().all()
    
    items = []
    for assignment in assignments:
        team_result = await db.execute(
            select(Team).where(
                Team.id == assignment.team_id,
                Team.hackathon_id == hackathon_id
            )
        )
        team = team_result.scalar_one_or_none()
        
        if not team:
            continue
        
        eval_result = await db.execute(
            select(Evaluation).where(
                Evaluation.hackathon_id == hackathon_id,
                Evaluation.expert_user_id == current_user.id,
                Evaluation.team_id == team.id
            )
        )
        evaluation = eval_result.scalar_one_or_none()
        
        eval_status = evaluation.status.value if evaluation else "not_started"
        submitted_at = evaluation.submitted_at if evaluation else None
        
        if status and eval_status != status:
            continue
        
        items.append(AssignedTeamResponse(
            team_id=team.id,
            team_name=team.name,
            project_title=team.project_title,
            evaluation_status=eval_status,
            submitted_at=submitted_at
        ))
    
    total = len(items)
    start = (page - 1) * page_size
    end = start + page_size
    paginated_items = items[start:end]
    
    return AssignedTeamListResponse(
        items=paginated_items,
        page=page,
        page_size=page_size,
        total=total
    )


@router.get("/teams/{team_id}/my-evaluation", response_model=MyEvaluationResponse)
async def get_my_evaluation(
    hackathon_id: UUID,
    team_id: UUID,
    current_user: User = Depends(expert_required),
    db: AsyncSession = Depends(get_db)
):
    """Get evaluation form for current expert"""
    # Verify assignment
    assignment_result = await db.execute(
        select(ExpertTeamAssignment)
        .where(
            ExpertTeamAssignment.hackathon_id == hackathon_id,
            ExpertTeamAssignment.expert_user_id == current_user.id,
            ExpertTeamAssignment.team_id == team_id
        )
    )
    assignment = assignment_result.scalar_one_or_none()
    
    if not assignment:
        raise HTTPException(
            status_code=403,
            detail="You are not assigned to evaluate this team"
        )
    
    # Get team info
    team_result = await db.execute(select(Team).where(Team.id == team_id))
    team = team_result.scalar_one_or_none()
    
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")
    
    # Get criteria
    criteria_result = await db.execute(
        select(Criterion)
        .where(Criterion.hackathon_id == hackathon_id, Criterion.is_active == True)
        .order_by(Criterion.sort_order)
    )
    criteria = criteria_result.scalars().all()
    
    # Get existing evaluation
    eval_result = await db.execute(
        select(Evaluation)
        .where(
            Evaluation.hackathon_id == hackathon_id,
            Evaluation.expert_user_id == current_user.id,
            Evaluation.team_id == team_id
        )
    )
    evaluation = eval_result.scalar_one_or_none()
    
    # Get evaluation items if exists
    items = []
    if evaluation:
        items_result = await db.execute(
            select(EvaluationItem)
            .where(EvaluationItem.evaluation_id == evaluation.id)
        )
        items = items_result.scalars().all()
    
    # Build criteria with scores
    criteria_items = []
    items_dict = {item.criterion_id: item for item in items}
    
    for c in criteria:
        item = items_dict.get(c.id)
        criteria_items.append({
            "criterion_id": c.id,
            "title": c.title,
            "description": c.description,
            "max_score": float(c.max_score),
            "weight_percent": float(c.weight_percent),
            "raw_score": float(item.raw_score) if item else None,
            "comment": item.comment if item else None
        })
    
    return MyEvaluationResponse(
        team_id=team.id,
        team_name=team.name,
        project_title=team.project_title,
        evaluation_id=evaluation.id if evaluation else None,
        status=evaluation.status.value if evaluation else "not_started",
        overall_comment=evaluation.overall_comment if evaluation else None,
        criteria=criteria_items,
        submitted_at=evaluation.submitted_at if evaluation else None
    )


@router.put("/teams/{team_id}/my-evaluation/draft")
async def save_evaluation_draft(
    hackathon_id: UUID,
    team_id: UUID,
    draft_data: EvaluationDraftRequest,
    current_user: User = Depends(expert_required),
    db: AsyncSession = Depends(get_db)
):
    """Save evaluation draft"""
    # Verify assignment
    assignment_result = await db.execute(
        select(ExpertTeamAssignment)
        .where(
            ExpertTeamAssignment.hackathon_id == hackathon_id,
            ExpertTeamAssignment.expert_user_id == current_user.id,
            ExpertTeamAssignment.team_id == team_id
        )
    )
    assignment = assignment_result.scalar_one_or_none()
    
    if not assignment:
        raise HTTPException(status_code=403, detail="Not assigned to this team")
    
    # Get or create evaluation
    eval_result = await db.execute(
        select(Evaluation)
        .where(
            Evaluation.hackathon_id == hackathon_id,
            Evaluation.expert_user_id == current_user.id,
            Evaluation.team_id == team_id
        )
    )
    evaluation = eval_result.scalar_one_or_none()
    
    if not evaluation:
        evaluation = Evaluation(
            hackathon_id=hackathon_id,
            expert_user_id=current_user.id,
            team_id=team_id,
            status=EvaluationStatus.DRAFT
        )
        db.add(evaluation)
        await db.flush()
    elif evaluation.status == EvaluationStatus.SUBMITTED:
        raise HTTPException(status_code=400, detail="Evaluation already submitted")
    
    # Update overall comment
    if draft_data.overall_comment is not None:
        evaluation.overall_comment = draft_data.overall_comment
    
    # Update criteria scores
    if draft_data.criteria:
        for crit_data in draft_data.criteria:
            # Get or create evaluation item
            item_result = await db.execute(
                select(EvaluationItem)
                .where(
                    EvaluationItem.evaluation_id == evaluation.id,
                    EvaluationItem.criterion_id == crit_data.criterion_id
                )
            )
            item = item_result.scalar_one_or_none()
            
            if not item:
                item = EvaluationItem(
                    evaluation_id=evaluation.id,
                    criterion_id=crit_data.criterion_id,
                    raw_score=crit_data.raw_score,
                    comment=crit_data.comment
                )
                db.add(item)
            else:
                if crit_data.raw_score is not None:
                    item.raw_score = crit_data.raw_score
                if crit_data.comment is not None:
                    item.comment = crit_data.comment
    
    await db.commit()
    
    return {"message": "Draft saved successfully", "evaluation_id": str(evaluation.id)}


@router.post("/teams/{team_id}/my-evaluation/submit")
async def submit_evaluation(
    hackathon_id: UUID,
    team_id: UUID,
    submit_data: EvaluationSubmitRequest,
    current_user: User = Depends(expert_required),
    db: AsyncSession = Depends(get_db)
):
    """Submit final evaluation"""
    # Verify assignment
    assignment_result = await db.execute(
        select(ExpertTeamAssignment)
        .where(
            ExpertTeamAssignment.hackathon_id == hackathon_id,
            ExpertTeamAssignment.expert_user_id == current_user.id,
            ExpertTeamAssignment.team_id == team_id
        )
    )
    assignment = assignment_result.scalar_one_or_none()
    
    if not assignment:
        raise HTTPException(status_code=403, detail="Not assigned to this team")
    
    # Get evaluation
    eval_result = await db.execute(
        select(Evaluation)
        .where(
            Evaluation.hackathon_id == hackathon_id,
            Evaluation.expert_user_id == current_user.id,
            Evaluation.team_id == team_id
        )
    )
    evaluation = eval_result.scalar_one_or_none()
    
    if not evaluation:
        raise HTTPException(status_code=404, detail="No draft evaluation found")
    
    if evaluation.status == EvaluationStatus.SUBMITTED:
        raise HTTPException(status_code=400, detail="Evaluation already submitted")
    
    # Verify all criteria have scores
    criteria_result = await db.execute(
        select(Criterion)
        .where(Criterion.hackathon_id == hackathon_id, Criterion.is_active == True)
    )
    criteria = criteria_result.scalars().all()
    
    items_result = await db.execute(
        select(EvaluationItem)
        .where(EvaluationItem.evaluation_id == evaluation.id)
    )
    items = {item.criterion_id: item for item in items_result.scalars().all()}
    
    missing_criteria = [c.id for c in criteria if c.id not in items]
    if missing_criteria:
        raise HTTPException(
            status_code=400,
            detail=f"Missing scores for criteria: {missing_criteria}"
        )
    
    # Submit
    evaluation.status = EvaluationStatus.SUBMITTED
    evaluation.overall_comment = submit_data.overall_comment or evaluation.overall_comment
    evaluation.submitted_at = datetime.now(timezone.utc)
    
    await db.commit()
    
    return {"message": "Evaluation submitted successfully", "evaluation_id": str(evaluation.id)}