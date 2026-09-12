from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field


class ResearchProjectCreate(BaseModel):
    business_id: str
    location_id: str
    research_scope: Optional[str] = "local_5km"


class ResearchProjectResponse(BaseModel):
    id: str
    business_id: str
    location_id: str
    status: str = Field(description="PLANNED, SECONDARY_RESEARCH, PRIMARY_RESEARCH, ANALYSIS, COMPLETED, FAILED")
    created_at: datetime
    updated_at: datetime


class ResearchQuestionItem(BaseModel):
    id: str
    question: str
    category: str = Field(description="demand, competition, pricing, supplier, distribution, risk")
    status: str = "open"
