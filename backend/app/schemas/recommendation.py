from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class RecommendationRequest(BaseModel):
    entrepreneur_id: Optional[str] = None
    business_id: Optional[str] = None
    override_profile: Optional[Dict[str, Any]] = None


class RuleEvaluationResult(BaseModel):
    rule_id: Optional[str] = None
    field_name: str
    operator: str
    expected_value: Any
    actual_value: Any
    passed: bool
    is_mandatory: bool = True
    rule_type: str = "eligibility"
    error_message: Optional[str] = None
    description: str = ""


class SchemeBenefitEstimate(BaseModel):
    estimated_subsidy: float = Field(ge=0.0, description="Estimated grant/subsidy amount in INR")
    estimated_loan: float = Field(ge=0.0, description="Estimated eligible bank loan amount in INR")
    estimated_own_contribution: float = Field(ge=0.0, description="Required entrepreneur margin money in INR")
    effective_project_cost: float = Field(ge=0.0, description="Net project cost after subsidy reduction in INR")
    subsidy_percentage: float = Field(ge=0.0, le=100.0, default=0.0)
    interest_subsidy_pct: float = Field(ge=0.0, default=0.0)
    calculation_breakdown: List[str] = Field(default_factory=list)
    is_estimate: bool = True


class SchemeExplanation(BaseModel):
    summary: str
    why_selected: str
    why_eligible: List[str] = Field(default_factory=list)
    passed_rules: List[str] = Field(default_factory=list)
    failed_rules: List[str] = Field(default_factory=list)
    missing_information: List[str] = Field(default_factory=list)
    financial_breakdown: List[str] = Field(default_factory=list)
    official_source: str
    official_portal_url: Optional[str] = None
    official_disclaimer: str = (
        "Calculations and eligibility indications are estimates based on standard scheme rules. "
        "Final approval and disbursement are subject to verification and sanction by the nodal bank or implementing authority."
    )


class SchemeRecommendationItem(BaseModel):
    scheme_id: str
    scheme_code: str
    official_name: str
    authority: str
    scheme_type: str = "CENTRAL"
    eligibility_status: str = Field(
        description="eligible, conditionally_eligible, needs_information, ineligible"
    )
    suitability_score: float = Field(ge=0.0, le=1.0, description="Combined weighted score")
    semantic_score: float = Field(ge=0.0, le=1.0, default=0.0)
    eligibility_score: float = Field(ge=0.0, le=1.0, default=0.0)
    business_relevance_score: float = Field(ge=0.0, le=1.0, default=0.0)
    financial_fit_score: float = Field(ge=0.0, le=1.0, default=0.0)
    location_fit_score: float = Field(ge=0.0, le=1.0, default=0.0)
    
    matched_rules: List[RuleEvaluationResult] = Field(default_factory=list)
    failed_rules: List[RuleEvaluationResult] = Field(default_factory=list)
    missing_rules: List[RuleEvaluationResult] = Field(default_factory=list)
    
    benefit_estimate: SchemeBenefitEstimate
    explanation: SchemeExplanation
    official_portal_url: Optional[str] = None
    key_conditions: List[str] = Field(default_factory=list)


class RecommendationRunResponse(BaseModel):
    run_id: str
    entrepreneur_id: str
    business_id: Optional[str] = None
    recommendations: List[SchemeRecommendationItem]
    total_schemes_evaluated: int
    eligible_count: int
    needs_info_count: int
    ineligible_count: int
    generated_at: datetime
