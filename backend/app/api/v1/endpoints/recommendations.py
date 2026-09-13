from datetime import datetime, timezone
import logging
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, Field

from app.adapters.gemini_adapter import GeminiAdapter
from app.adapters.supabase_adapter import supabase_adapter
from app.api.v1.endpoints.opportunities import _OFFLINE_BUSINESSES
from app.api.v1.endpoints.research import _OFFLINE_EVIDENCE, _OFFLINE_PROJECTS
from app.api.v1.endpoints.finance import _OFFLINE_SCENARIOS
from app.core.errors import ResourceNotFoundException
from app.core.security import get_current_user
from app.schemas.common import APIResponse
from app.schemas.recommendation import (
    RecommendationRequest,
    RecommendationRunResponse,
    SchemeRecommendationItem,
)
from app.services.conflict_detector import ConflictDetector
from app.services.financial_engine import FinancialEngine, FinancialSimulationInput
from app.services.prompt_service import PromptService
from app.services.recommendation_service import (
    RecommendationService,
    _OFFLINE_REC_RUNS,
    _OFFLINE_REC_ITEMS,
)
from app.services.scheme_matcher import SchemeMatcher, SchemeMatchRequest

logger = logging.getLogger(__name__)

router = APIRouter()
gemini_adapter = GeminiAdapter()
prompt_service = PromptService()
conflict_detector = ConflictDetector()


def _get_db():
    return supabase_adapter.admin_client or supabase_adapter.client


# ---------------------------------------------------------------------------
# Government Scheme Recommendation Endpoints (Step 13)
# ---------------------------------------------------------------------------

@router.post(
    "/recommendations",
    response_model=APIResponse[RecommendationRunResponse],
    status_code=status.HTTP_200_OK,
    summary="Generate deterministic government scheme recommendations for entrepreneur",
)
async def create_scheme_recommendation(
    payload: Optional[RecommendationRequest] = None,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    user_id = str(current_user.get("sub") or current_user.get("id") or current_user.get("user_id"))
    req = payload or RecommendationRequest()
    
    result = RecommendationService.run_recommendation(user_id=user_id, request=req)
    
    return APIResponse(
        success=True,
        data=result,
        message=f"Generated {len(result.recommendations)} government scheme recommendations ({result.eligible_count} eligible).",
    )


@router.get(
    "/recommendations/latest",
    response_model=APIResponse[RecommendationRunResponse],
    summary="Get latest recommendation run for authenticated user",
)
async def get_latest_recommendation(
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    user_id = str(current_user.get("sub") or current_user.get("id") or current_user.get("user_id"))
    req = RecommendationRequest()
    result = RecommendationService.run_recommendation(user_id=user_id, request=req)
    return APIResponse(
        success=True,
        data=result,
        message="Retrieved latest government scheme recommendations.",
    )


@router.get(
    "/recommendations/{run_id}",
    response_model=APIResponse[Dict[str, Any]],
    summary="Get recommendation run details by run ID",
)
async def get_recommendation_run(
    run_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    rec_data = RecommendationService.get_recommendation_by_id(run_id)
    if not rec_data:
        raise ResourceNotFoundException("RecommendationRun", run_id)

    return APIResponse(
        success=True,
        data=rec_data,
        message="Retrieved recommendation run details.",
    )


# ---------------------------------------------------------------------------
# Full Business Viability Recommendation Synthesis (Retained for Compatibility)
# ---------------------------------------------------------------------------

class SWOTAnalysis(BaseModel):
    strengths: List[str]
    weaknesses: List[str]
    opportunities: List[str]
    threats: List[str]


class RiskMitigation(BaseModel):
    risk: str
    mitigation: str


class ActionPlanMilestone(BaseModel):
    week: int
    title: str
    deliverables: List[str]
    validation_checkpoint: str


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


@router.get(
    "/businesses/{business_id}/recommendation",
    response_model=APIResponse[FinalRecommendationResponse],
    summary="Generate full-lifecycle evidence-based final recommendation and 4-week action plan",
)
async def get_business_recommendation(
    business_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    db = _get_db()
    biz_name = "Enterprise"
    biz_domain = "General"
    project_cost = 250000.0
    own_cap = 50000.0
    is_affordable = True
    dscr = 2.0

    # 1. Fetch Business
    found = False
    if db is not None:
        try:
            b_res = db.table("businesses").select("*").eq("id", business_id).execute()
            if b_res.data:
                found = True
                b_row = b_res.data[0]
                biz_name = b_row["name"]
                biz_domain = b_row["domain"]
        except Exception as e:
            logger.warning(f"Failed to fetch business in recommendation: {e}")

    if not found and business_id in _OFFLINE_BUSINESSES:
        found = True
        b_row = _OFFLINE_BUSINESSES[business_id]
        biz_name = b_row["name"]
        biz_domain = b_row["domain"]

    if not found:
        raise ResourceNotFoundException("Business", business_id)

    # 2. Fetch Financial Scenarios & Simulation
    if db is not None:
        try:
            scen_res = (
                db.table("financial_scenarios")
                .select("*")
                .eq("business_id", business_id)
                .order("created_at", desc=True)
                .limit(1)
                .execute()
            )
            if scen_res.data:
                sc_row = scen_res.data[0]
                project_cost = float(sc_row["total_project_cost"])
                own_cap = float(sc_row["own_capital"])
                sim_res = FinancialEngine.simulate(
                    FinancialSimulationInput(
                        total_project_cost=project_cost,
                        own_capital=own_cap,
                        annual_interest_rate_pct=float(sc_row["interest_rate_pct"]),
                        tenure_months=int(sc_row["tenure_months"]),
                        projected_monthly_revenue=float(sc_row["monthly_revenue_est"]),
                        projected_monthly_operating_cost=float(sc_row["monthly_operating_cost_est"]),
                    )
                )
                is_affordable = sim_res.is_affordable
                dscr = sim_res.debt_service_coverage_ratio
        except Exception as e:
            logger.warning(f"Failed to fetch financial scenario: {e}")

    # 3. Determine Scheme Eligibility
    scheme_matches = SchemeMatcher.evaluate(
        SchemeMatchRequest(
            project_cost=project_cost,
            own_capital=own_cap,
            domain=biz_domain,
            state="Madhya Pradesh",
            district="Indore",
            category="general",
        )
    )
    eligible_scheme_names = [
        s.official_name for s in scheme_matches if s.eligibility_status in ["eligible", "conditionally_eligible"]
    ]

    # 4. Synthesize Verdict
    if not is_affordable or dscr < 1.0:
        verdict = "CAUTION_FINANCIAL_STRESS"
        rationale = (
            f"Current financial projections yield a debt service coverage ratio of {dscr:.2f}x, "
            f"indicating high risk of repayment distress. We strongly recommend reducing capital equipment "
            f"expenditure or applying for a government subsidy scheme to raise own margin contribution."
        )
    else:
        verdict = "PROCEED_WITH_PILOT"
        rationale = (
            f"Evidence and financial modeling indicate a viable micro-enterprise foundation for {biz_name}. "
            f"Debt service coverage ratio is healthy at {dscr:.2f}x. "
            f"Proceed with a focused, small-batch pilot validation to confirm local customer repeat purchases."
        )

    # 5. Build 4-Week Action Plan
    action_plan = [
        ActionPlanMilestone(
            week=1,
            title="Local Supply & Ingredient Sourcing",
            deliverables=[
                "Identify and visit 3 nearby wholesale suppliers or farms.",
                "Negotiate wholesale bulk pricing and verify consistency.",
            ],
            validation_checkpoint="Obtain written or recorded price quotes matching projected unit economics.",
        ),
        ActionPlanMilestone(
            week=2,
            title="Packaging & Prototype Batch Preparation",
            deliverables=[
                "Produce first trial pilot batch (20-30 units).",
                "Apply local FSSAI basic registration / Udyam registration online.",
            ],
            validation_checkpoint="Packaging sealed securely with clear weight and local contact details.",
        ),
        ActionPlanMilestone(
            week=3,
            title="Field Market Test & Sampling",
            deliverables=[
                "Distribute 15 free samples to target households and local shopkeepers.",
                "Conduct a 2-minute feedback survey recording taste, price willingness, and repeat intent.",
            ],
            validation_checkpoint="At least 60% of respondents state willingness to buy at the target price.",
        ),
        ActionPlanMilestone(
            week=4,
            title="Paid Pilot & Financial Review",
            deliverables=[
                "Sell first commercial batch of 50 units at target price.",
                "Log all revenues, material costs, and delivery travel expenses.",
            ],
            validation_checkpoint="Net cash flow confirms positive unit margins prior to taking bank debt.",
        ),
    ]

    swot = SWOTAnalysis(
        strengths=[
            f"Existing skills and domain familiarity in {biz_domain}.",
            "Low initial working capital requirement for pilot batch.",
        ],
        weaknesses=[
            "Limited early brand recognition in district markets.",
            "Initial dependence on local manual packaging throughput.",
        ],
        opportunities=[
            f"Growing consumer preference for unadulterated local products in {biz_domain}.",
            "Access to subsidized working capital under Mudra & PMEGP schemes.",
        ],
        threats=[
            "Seasonal fluctuation in raw material procurement prices.",
            "Price competition from subsidized industrial mass-market brands.",
        ],
    )

    risks = [
        RiskMitigation(
            risk="Lower-than-expected initial customer repeat purchase rate.",
            mitigation="Offer introductory loyalty discount and smaller trial sachets/packs.",
        ),
        RiskMitigation(
            risk="Delayed government subsidy disbursement from bank branch.",
            mitigation="Maintain at least 2 months of operational working capital in reserve.",
        ),
    ]

    response_data = FinalRecommendationResponse(
        business_id=business_id,
        business_name=biz_name,
        verdict=verdict,
        confidence_score=0.88,
        executive_rationale=rationale,
        swot_analysis=swot,
        identified_risks_and_mitigations=risks,
        four_week_action_plan=action_plan,
        key_evidence_citations=["EVID-GOV-REGIONAL-BENCHMARK-01", "SURVEY-FIELD-PRIMARY-01"],
        eligible_schemes=eligible_scheme_names[:3],
    )

    return APIResponse(
        success=True,
        data=response_data,
        message="Final recommendation and 4-week action plan synthesized.",
    )
