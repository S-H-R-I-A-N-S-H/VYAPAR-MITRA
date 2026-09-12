from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field


class BusinessCreate(BaseModel):
    name: str
    domain: str = Field(description="e.g. Dairy, Agriculture, Retail, Manufacturing")
    product_or_service: str
    business_model: Optional[str] = None
    description: Optional[str] = None
    target_customer: Optional[str] = None
    intended_market: Optional[str] = None
    scale: Optional[str] = "micro"


class BusinessVersionCreate(BaseModel):
    business_id: str
    business_definition: str
    assumptions: dict = Field(default_factory=dict)
    source: str = Field(default="USER", description="USER, AI_DRAFT, AI_REFINED")


class BusinessResponse(BusinessCreate):
    id: str
    entrepreneur_id: str
    status: str = Field(default="IDEA", description="IDEA, VALIDATING, RECOMMENDED, PLANNED, OPERATING")
    created_at: datetime
    updated_at: datetime


class BusinessOpportunityItem(BaseModel):
    title: str
    domain: str
    description: str
    why_fit: str
    estimated_capital_required: float
    feasibility_score: Optional[float] = None
    local_demand_indicator: str = "medium"
