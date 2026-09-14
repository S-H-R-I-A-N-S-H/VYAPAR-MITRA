from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field


class EvidenceCreate(BaseModel):
    claim: str = Field(..., max_length=2000)
    extracted_value: Optional[str] = Field(default=None, max_length=500)
    unit: Optional[str] = Field(default=None, max_length=100)
    source_name: str = Field(..., max_length=300)
    source_url: Optional[str] = Field(default=None, max_length=1000)
    source_type: str = Field(default="TRUSTED_WEB", max_length=100, description="GOVERNMENT, TRUSTED_WEB, FIELD_PRIMARY, LOCAL_SURVEY")
    geography: Optional[str] = Field(default=None, max_length=200)
    confidence_score: float = Field(default=0.80, ge=0.0, le=1.0)



class EvidenceItem(EvidenceCreate):
    id: str
    research_project_id: str
    created_at: datetime


class ConflictItem(BaseModel):
    id: str
    topic: str
    secondary_claim: str
    secondary_source: str
    primary_claim: str
    primary_source: str
    discrepancy_explanation: str
    impact_on_confidence: str = Field(description="high_risk, medium_risk, low_risk")
    suggested_action: str
