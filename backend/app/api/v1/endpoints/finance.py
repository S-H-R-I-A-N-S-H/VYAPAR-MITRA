from datetime import datetime, timezone
import logging
import uuid
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, Field

from app.adapters.gemini_adapter import GeminiAdapter
from app.adapters.supabase_adapter import supabase_adapter
from app.core.errors import ResourceNotFoundException
from app.core.security import get_current_user
from app.schemas.common import APIResponse
from app.schemas.finance import (
    FinancialSimulationInput,
    FinancialSimulationResult,
)
from app.services.financial_engine import FinancialEngine
from app.services.prompt_service import (
    FinancialExplanationResponse,
    PromptService,
)

logger = logging.getLogger(__name__)

router = APIRouter()
gemini_adapter = GeminiAdapter()
prompt_service = PromptService()

_OFFLINE_SCENARIOS: Dict[str, Dict[str, Any]] = {}


def _get_db():
    return supabase_adapter.admin_client or supabase_adapter.client


# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------

class FinancialScenarioCreate(BaseModel):
    business_id: str
    scenario_name: str = "Base Scenario"
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
    explanation: Optional[FinancialExplanationResponse] = None
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


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@router.post(
    "/simulate",
    response_model=APIResponse[FinancialSimulationResult],
    summary="Ad-hoc deterministic financial simulation",
)
async def simulate_financials(payload: FinancialSimulationInput):
    """
    Executes authoritative deterministic financial modeling.
    Calculates EMI, cash flow, DSCR, and affordability risk.
    """
    result = FinancialEngine.simulate(payload)
    return APIResponse(
        success=True,
        data=result,
        message="Financial simulation completed successfully.",
    )


@router.post(
    "/scenarios",
    response_model=APIResponse[FinancialScenarioResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create and persist a financial scenario with deterministic math and AI risk narrative",
)
async def create_financial_scenario(
    scen_in: FinancialScenarioCreate,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    db = _get_db()
    now = datetime.now(timezone.utc)
    scen_id = str(uuid.uuid4())

    # 1. Authoritative deterministic math calculation
    sim_input = FinancialSimulationInput(
        total_project_cost=scen_in.total_project_cost,
        own_capital=scen_in.own_capital,
        annual_interest_rate_pct=scen_in.annual_interest_rate_pct,
        tenure_months=scen_in.tenure_months,
        projected_monthly_revenue=scen_in.projected_monthly_revenue,
        projected_monthly_operating_cost=scen_in.projected_monthly_operating_cost,
    )
    sim_result = FinancialEngine.simulate(sim_input)

    # 2. Lookup business name for contextual grounding
    business_name = "Micro-Enterprise"
    if db is not None:
        try:
            b_res = db.table("businesses").select("name").eq("id", scen_in.business_id).execute()
            if b_res.data:
                business_name = b_res.data[0]["name"]
        except Exception as e:
            logger.warning(f"Failed to lookup business name: {e}")

    # 3. AI narrative generation (strictly grounded in deterministic numbers)
    explanation: Optional[FinancialExplanationResponse] = None
    if gemini_adapter.is_live:
        try:
            sys_p, user_p = prompt_service.build_financial_explanation_prompt(
                simulation_result=sim_result,
                business_name=business_name,
            )
            explanation = await gemini_adapter.generate_structured_output(
                system_instruction=sys_p,
                user_prompt=user_p,
                response_schema=FinancialExplanationResponse,
            )
        except Exception as e:
            logger.warning(f"AI financial narrative generation failed ({e}); using grounded fallback.")

    if explanation is None:
        explanation = FinancialExplanationResponse(
            executive_summary=(
                f"For {business_name}, requiring ₹{sim_result.required_loan_amount:,.0f} debt financing, "
                f"the project yields a projected net monthly profit of ₹{sim_result.projected_monthly_profit:,.0f} "
                f"with an EMI of ₹{sim_result.monthly_emi:,.0f}."
            ),
            viability_analysis=(
                f"DSCR stands at {sim_result.debt_service_coverage_ratio:.2f}x, classified as "
                f"'{sim_result.affordability_risk_level.upper()}'. {sim_result.affordability_rationale}"
            ),
            key_financial_risks=[
                "High revenue volatility during first 3 ramp-up months.",
                "Cash flow buffer required for unexpected equipment maintenance.",
            ],
            breakeven_interpretation="Comfortable debt repayment buffer based on estimated unit margins.",
            suggested_actions=[
                "Maintain at least 2 months of EMI (₹{:.0f}) in emergency reserve.".format(sim_result.monthly_emi * 2),
                "Apply for interest-subsidized government schemes (e.g. Mudra / PMEGP).",
            ],
        )

    # 4. Database persistence
    if db is not None:
        try:
            scen_insert = {
                "id": scen_id,
                "business_id": scen_in.business_id,
                "scenario_name": scen_in.scenario_name,
                "total_project_cost": scen_in.total_project_cost,
                "own_capital": scen_in.own_capital,
                "loan_amount": sim_result.required_loan_amount,
                "interest_rate_pct": scen_in.annual_interest_rate_pct,
                "tenure_months": scen_in.tenure_months,
                "monthly_revenue_est": scen_in.projected_monthly_revenue,
                "monthly_operating_cost_est": scen_in.projected_monthly_operating_cost,
                "created_at": now.isoformat(),
            }
            db.table("financial_scenarios").insert(scen_insert).execute()

            # Insert results
            db.table("financial_results").insert({
                "id": str(uuid.uuid4()),
                "scenario_id": scen_id,
                "monthly_emi": sim_result.monthly_emi,
                "total_interest": sim_result.total_interest_payable,
                "total_repayment": sim_result.total_repayment_amount,
                "monthly_net_profit": sim_result.projected_monthly_profit,
                "monthly_cash_flow_after_emi": sim_result.net_cash_flow_after_emi,
                "debt_service_coverage_ratio": sim_result.debt_service_coverage_ratio,
                "is_affordable": sim_result.is_affordable,
                "affordability_risk_level": sim_result.affordability_risk_level,
                "affordability_rationale": sim_result.affordability_rationale,
                "created_at": now.isoformat(),
            }).execute()

            return APIResponse(
                success=True,
                data=FinancialScenarioResponse(
                    id=scen_id,
                    business_id=scen_in.business_id,
                    scenario_name=scen_in.scenario_name,
                    simulation_result=sim_result,
                    explanation=explanation,
                    created_at=now,
                ),
                message="Financial scenario created and modeled successfully.",
            )
        except Exception as e:
            logger.warning(f"Database insert financial scenario failed: {e}")

    # Offline/sandbox fallback
    scen_data = {
        "id": scen_id,
        "business_id": scen_in.business_id,
        "scenario_name": scen_in.scenario_name,
        "total_project_cost": scen_in.total_project_cost,
        "own_capital": scen_in.own_capital,
        "annual_interest_rate_pct": scen_in.annual_interest_rate_pct,
        "tenure_months": scen_in.tenure_months,
        "projected_monthly_revenue": scen_in.projected_monthly_revenue,
        "projected_monthly_operating_cost": scen_in.projected_monthly_operating_cost,
        "simulation_result": sim_result,
        "explanation": explanation,
        "created_at": now,
    }
    _OFFLINE_SCENARIOS[scen_id] = scen_data

    return APIResponse(
        success=True,
        data=FinancialScenarioResponse(
            id=scen_id,
            business_id=scen_in.business_id,
            scenario_name=scen_in.scenario_name,
            simulation_result=sim_result,
            explanation=explanation,
            created_at=now,
        ),
        message="Financial scenario modeled (sandbox mode).",
    )


@router.get(
    "/scenarios/{scenario_id}",
    response_model=APIResponse[FinancialScenarioResponse],
    summary="Get financial scenario details",
)
async def get_financial_scenario(
    scenario_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    db = _get_db()
    if db is not None:
        try:
            res = db.table("financial_scenarios").select("*").eq("id", scenario_id).execute()
            if res.data:
                rec = res.data[0]
                sim_input = FinancialSimulationInput(
                    total_project_cost=float(rec["total_project_cost"]),
                    own_capital=float(rec["own_capital"]),
                    annual_interest_rate_pct=float(rec["interest_rate_pct"]),
                    tenure_months=int(rec["tenure_months"]),
                    projected_monthly_revenue=float(rec["monthly_revenue_est"]),
                    projected_monthly_operating_cost=float(rec["monthly_operating_cost_est"]),
                )
                sim_res = FinancialEngine.simulate(sim_input)
                return APIResponse(
                    success=True,
                    data=FinancialScenarioResponse(
                        id=str(rec["id"]),
                        business_id=str(rec["business_id"]),
                        scenario_name=rec["scenario_name"],
                        simulation_result=sim_res,
                        created_at=datetime.fromisoformat(rec["created_at"]),
                    ),
                )
        except Exception as e:
            logger.warning(f"Database get scenario failed: {e}")

    if scenario_id in _OFFLINE_SCENARIOS:
        s = _OFFLINE_SCENARIOS[scenario_id]
        return APIResponse(
            success=True,
            data=FinancialScenarioResponse(
                id=s["id"],
                business_id=s["business_id"],
                scenario_name=s["scenario_name"],
                simulation_result=s["simulation_result"],
                explanation=s["explanation"],
                created_at=s["created_at"],
            ),
        )

    raise ResourceNotFoundException("FinancialScenario", scenario_id)


@router.post(
    "/scenarios/{scenario_id}/what-if",
    response_model=APIResponse[WhatIfResponse],
    summary="Run what-if sensitivity stress analysis against base financial scenario",
)
async def run_what_if_stress_test(
    scenario_id: str,
    stress_in: WhatIfInput,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    # Fetch base scenario parameters
    scen_res = await get_financial_scenario(scenario_id, current_user)
    base_sim = scen_res.data.simulation_result

    # Retrieve base inputs
    db = _get_db()
    base_cost = base_sim.total_project_cost
    base_own = base_sim.own_capital
    base_rate = 9.5
    base_tenure = 36
    base_rev = base_sim.projected_monthly_profit + (base_cost * 0.05)  # estimate
    base_op_cost = base_rev - base_sim.projected_monthly_profit

    if db is not None:
        try:
            r = db.table("financial_scenarios").select("*").eq("id", scenario_id).execute()
            if r.data:
                row = r.data[0]
                base_cost = float(row["total_project_cost"])
                base_own = float(row["own_capital"])
                base_rate = float(row["interest_rate_pct"])
                base_tenure = int(row["tenure_months"])
                base_rev = float(row["monthly_revenue_est"])
                base_op_cost = float(row["monthly_operating_cost_est"])
        except Exception:
            pass

    if scenario_id in _OFFLINE_SCENARIOS:
        s = _OFFLINE_SCENARIOS[scenario_id]
        base_cost = s["total_project_cost"]
        base_own = s["own_capital"]
        base_rate = s["annual_interest_rate_pct"]
        base_tenure = s["tenure_months"]
        base_rev = s["projected_monthly_revenue"]
        base_op_cost = s["projected_monthly_operating_cost"]

    # Calculate Stressed Case
    stressed_rev = base_rev * (1.0 - (stress_in.revenue_drop_pct / 100.0))
    stressed_op_cost = base_op_cost * (1.0 + (stress_in.cost_increase_pct / 100.0))
    stressed_rate = base_rate + stress_in.interest_rate_delta_pct

    stressed_sim = FinancialEngine.simulate(
        FinancialSimulationInput(
            total_project_cost=base_cost,
            own_capital=base_own,
            annual_interest_rate_pct=stressed_rate,
            tenure_months=base_tenure,
            projected_monthly_revenue=stressed_rev,
            projected_monthly_operating_cost=stressed_op_cost,
        )
    )

    base_case = WhatIfCase(
        monthly_profit=base_sim.projected_monthly_profit,
        net_cash_flow=base_sim.net_cash_flow_after_emi,
        dscr=base_sim.debt_service_coverage_ratio,
        affordability_risk_level=base_sim.affordability_risk_level,
    )

    stressed_case = WhatIfCase(
        monthly_profit=stressed_sim.projected_monthly_profit,
        net_cash_flow=stressed_sim.net_cash_flow_after_emi,
        dscr=stressed_sim.debt_service_coverage_ratio,
        affordability_risk_level=stressed_sim.affordability_risk_level,
    )

    summary = (
        f"Under a {stress_in.revenue_drop_pct:.0f}% revenue drop and {stress_in.cost_increase_pct:.0f}% cost inflation, "
        f"net monthly cash flow moves from ₹{base_case.net_cash_flow:,.0f} to ₹{stressed_case.net_cash_flow:,.0f}. "
        f"Risk tier changes to {stressed_case.affordability_risk_level.upper()}."
    )

    return APIResponse(
        success=True,
        data=WhatIfResponse(
            scenario_id=scenario_id,
            base_case=base_case,
            stressed_case=stressed_case,
            stress_summary=summary,
        ),
        message="What-if sensitivity stress analysis completed.",
    )
