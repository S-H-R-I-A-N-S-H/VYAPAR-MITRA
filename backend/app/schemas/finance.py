from datetime import datetime
from typing import Any, List, Optional
from pydantic import BaseModel, Field



class FinancialSimulationInput(BaseModel):
    total_project_cost: float = Field(gt=0, description="Total cost in INR")
    own_capital: float = Field(ge=0, description="Entrepreneur's own margin contribution")
    loan_amount_requested: Optional[float] = Field(default=None, description="Requested debt")
    annual_interest_rate_pct: float = Field(default=9.5, ge=0, le=36.0, description="Annual rate in %")
    tenure_months: int = Field(default=36, ge=6, le=120, description="Repayment tenure in months")
    projected_monthly_revenue: float = Field(ge=0, description="Estimated monthly sales/revenue")
    projected_monthly_operating_cost: float = Field(ge=0, description="Estimated raw materials + overhead")


class AmortizationScheduleItem(BaseModel):
    month: int
    opening_balance: float
    emi: float
    principal: float
    interest: float
    closing_balance: float


class FinancialSimulationResult(BaseModel):
    total_project_cost: float
    own_capital: float
    required_loan_amount: float
    monthly_emi: float
    total_interest_payable: float
    total_repayment_amount: float
    projected_monthly_profit: float
    net_cash_flow_after_emi: float
    debt_service_coverage_ratio: float
    is_affordable: bool
    affordability_risk_level: str = Field(description="safe, moderate, critical")
    affordability_rationale: str
    amortization_preview: List[AmortizationScheduleItem] = Field(default_factory=list)


class FinancialScenarioCreate(BaseModel):
    business_id: str
    scenario_name: str = Field(default="Base Scenario", max_length=200)
    total_project_cost: float = Field(gt=0)
    own_capital: float = Field(ge=0)
    annual_interest_rate_pct: float = Field(default=9.5, ge=0, le=36.0)
    tenure_months: int = Field(default=36, ge=6, le=120)
    projected_monthly_revenue: float = Field(ge=0)
    projected_monthly_operating_cost: float = Field(ge=0)


class FinancialScenarioResponse(BaseModel):
    id: str
    business_id: str
    scenario_name: str
    simulation_result: FinancialSimulationResult
    explanation: Optional[Any] = None
    created_at: datetime


class WhatIfInput(BaseModel):
    revenue_drop_pct: float = Field(default=20.0, ge=0, le=100.0)
    cost_increase_pct: float = Field(default=10.0, ge=0, le=100.0)
    interest_rate_delta_pct: float = Field(default=0.0, ge=-5.0, le=10.0)


class WhatIfCase(BaseModel):
    monthly_profit: float
    net_cash_flow: float
    dscr: float
    affordability_risk_level: str


class WhatIfResponse(BaseModel):
    scenario_id: str
    base_case: WhatIfCase
    stressed_case: WhatIfCase
    stress_summary: str

