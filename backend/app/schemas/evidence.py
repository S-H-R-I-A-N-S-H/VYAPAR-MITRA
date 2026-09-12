from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field


class EvidenceItem(BaseModel):
    id: str
    research_project_id: str
    claim: str
    extracted_value: Optional[str] = None
    unit: Optional[str] = None
    source_name: str
    source_url: Optional[str] = None
    source_type: str = Field(description="GOVERNMENT, TRUSTED_WEB, FIELD_PRIMARY, LOCAL_SURVEY")
    geography: Optional[str] = None
    confidence_score: float = Field(ge=0.0, le=1.0)
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
