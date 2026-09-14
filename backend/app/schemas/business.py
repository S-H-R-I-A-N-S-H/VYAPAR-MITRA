from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field


class BusinessCreate(BaseModel):
    name: str = Field(..., max_length=200)
    domain: str = Field(..., max_length=100, description="e.g. Dairy, Agriculture, Retail, Manufacturing")
    product_or_service: str = Field(..., max_length=300)
    business_model: Optional[str] = Field(default=None, max_length=500)
    description: Optional[str] = Field(default=None, max_length=5000)
    target_customer: Optional[str] = Field(default=None, max_length=500)
    intended_market: Optional[str] = Field(default=None, max_length=500)
    scale: Optional[str] = Field(default="micro", max_length=50)


class BusinessVersionCreate(BaseModel):
    business_id: str
    business_definition: str = Field(..., max_length=5000)
    assumptions: dict = Field(default_factory=dict)
    source: str = Field(default="USER", max_length=50, description="USER, AI_DRAFT, AI_REFINED")


class BusinessResponse(BusinessCreate):
    id: str
    entrepreneur_id: str
    status: str = Field(default="IDEA", description="IDEA, VALIDATING, RECOMMENDED, PLANNED, OPERATING")
    created_at: datetime
    updated_at: datetime


class BusinessUpdate(BaseModel):
    name: Optional[str] = Field(default=None, max_length=200)
    status: Optional[str] = Field(default=None, max_length=50)
    domain: Optional[str] = Field(default=None, max_length=100)
    product_or_service: Optional[str] = Field(default=None, max_length=300)
    business_model: Optional[str] = Field(default=None, max_length=500)
    description: Optional[str] = Field(default=None, max_length=5000)
    target_customer: Optional[str] = Field(default=None, max_length=500)
    intended_market: Optional[str] = Field(default=None, max_length=500)
    scale: Optional[str] = Field(default=None, max_length=50)



class BusinessVersionResponse(BaseModel):
    id: str
    business_id: str
    version_number: int
    business_definition: str
    assumptions: dict
    source: str
    created_at: datetime
    confirmed_at: Optional[datetime] = None


class BusinessOpportunityItem(BaseModel):
    title: str
    domain: str
    description: str
    why_fit: str
    estimated_capital_required: float
    feasibility_score: Optional[float] = None
    local_demand_indicator: str = "medium"
