# backend/app/schemas/criterion.py
from pydantic import BaseModel, Field, validator
from uuid import UUID
from typing import Optional, List
from decimal import Decimal

class CriterionCreate(BaseModel):
    title: str = Field(..., max_length=150)
    description: Optional[str] = None
    max_score: float = Field(..., gt=0)
    weight_percent: float = Field(..., ge=0, le=100)
    sort_order: int = Field(..., gt=0)
    is_active: bool = True

    @validator('max_score')
    def validate_max_score(cls, v):
        if v <= 0:
            raise ValueError('max_score must be greater than 0')
        return v

class CriterionUpdate(BaseModel):
    title: Optional[str] = Field(None, max_length=150)
    description: Optional[str] = None
    max_score: Optional[float] = Field(None, gt=0)
    weight_percent: Optional[float] = Field(None, ge=0, le=100)
    sort_order: Optional[int] = Field(None, gt=0)
    is_active: Optional[bool] = None

class CriterionResponse(BaseModel):
    id: UUID
    title: str
    description: Optional[str] = None
    max_score: float
    weight_percent: float
    sort_order: int
    is_active: bool
    created_at: datetime
    updated_at: datetime

class CriteriaListResponse(BaseModel):
    items: List[CriterionResponse]
    total_weight: float
    weights_valid: bool

class CriteriaReorderItem(BaseModel):
    id: UUID
    sort_order: int

class CriteriaReorderRequest(BaseModel):
    items: List[CriteriaReorderItem]