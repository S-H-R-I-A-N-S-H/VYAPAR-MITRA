from typing import List, Optional
from pydantic import BaseModel, Field


class SWOTAnalysis(BaseModel):
    strengths: List[str] = Field(default_factory=list)
    weaknesses: List[str] = Field(default_factory=list)
    opportunities: List[str] = Field(default_factory=list)
    threats: List[str] = Field(default_factory=list)


class RiskMitigation(BaseModel):
    risk: str = Field(..., max_length=500)
    mitigation: str = Field(..., max_length=1000)


class ActionPlanMilestone(BaseModel):
    week: int
    title: str = Field(..., max_length=200)
    deliverables: List[str] = Field(default_factory=list)
    validation_checkpoint: str = Field(..., max_length=500)


class FinalRecommendationResponse(BaseModel):
    business_id: str
    business_name: str
    verdict: str = Field(
        description="PROCEED_WITH_PILOT, NEEDS_MORE_EVIDENCE, CAUTION_FINANCIAL_STRESS, PIVOT"
    )
    confidence_score: float = Field(ge=0.0, le=1.0)
    executive_rationale: str
    swot_analysis: SWOTAnalysis
    identified_risks_and_mitigations: List[RiskMitigation]
    four_week_action_plan: List[ActionPlanMilestone]
    key_evidence_citations: List[str]
    eligible_schemes: List[str]
