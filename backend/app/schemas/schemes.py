from typing import List, Optional
from pydantic import BaseModel, Field


class SchemeMatchRequest(BaseModel):
    project_cost: float
    own_capital: float
    domain: str
    state: str
    district: Optional[str] = None
    category: str = "general"
    gender: Optional[str] = None


class MatchedScheme(BaseModel):
    scheme_id: str
    official_name: str
    authority: str
    max_loan_limit: float
    max_subsidy_pct: float
    subsidy_amount_estimate: float
    interest_rate_subsidy_pct: Optional[float] = 0.0
    eligibility_status: str = Field(description="eligible, conditionally_eligible, ineligible")
    rationale: str
    key_conditions: List[str]
    official_portal_url: Optional[str] = None


class SchemeItem(BaseModel):
    id: Optional[str] = None
    scheme_code: str
    official_name: str
    authority: str
    max_loan_limit: Optional[float] = None
    max_subsidy_pct: Optional[float] = 0.0
    official_portal_url: Optional[str] = None
    eligibility_rules: dict = Field(default_factory=dict)
    is_active: bool = True

