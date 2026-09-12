from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field


class EvidenceCreate(BaseModel):
    claim: str
    extracted_value: Optional[str] = None
    unit: Optional[str] = None
    source_name: str
    source_url: Optional[str] = None
    source_type: str = Field(default="TRUSTED_WEB", description="GOVERNMENT, TRUSTED_WEB, FIELD_PRIMARY, LOCAL_SURVEY")
    geography: Optional[str] = None
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
