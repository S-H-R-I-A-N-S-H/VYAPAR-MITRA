import logging
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, Field

from app.adapters.supabase_adapter import supabase_adapter
from app.api.v1.endpoints.opportunities import _OFFLINE_BUSINESSES
from app.core.errors import ResourceNotFoundException
from app.core.security import get_current_user
from app.schemas.common import APIResponse
from app.schemas.evidence import EvidenceItem
from app.schemas.feasibility import FeasibilityScoreResult, MarketGapAnalysis, RiskAnalysis
from app.schemas.finance import FinancialSimulationResult
from app.services.market_gap_detector import MarketGapDetector
from app.services.opportunity_score import OpportunityScoreAnalyzer
from app.services.risk_analyzer import RiskAnalyzer

logger = logging.getLogger(__name__)

router = APIRouter()


def _get_db():
    return supabase_adapter.admin_client or supabase_adapter.client


class FeasibilityAnalysisRequest(BaseModel):
    evidence_items: List[EvidenceItem] = Field(
        default_factory=list,
        description="List of evidence items supporting feasibility analysis",
    )
    target_radius_km: float = Field(
        default=5.0,
        ge=0.1,
        description="Geographic catchment radius in kilometers",
    )
    financial_simulation: Optional[FinancialSimulationResult] = Field(
        default=None,
        description="Optional financial simulation result",
    )


@router.post(
    "/businesses/{business_id}/feasibility/analyze",
    response_model=APIResponse[FeasibilityScoreResult],
    status_code=status.HTTP_200_OK,
    summary="Analyze business feasibility using evidence, market gap, risk, and financial signals",
)
async def analyze_business_feasibility(
    business_id: str,
    req_body: Optional[FeasibilityAnalysisRequest] = None,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """
    Triggers business feasibility analysis.

    Validates business lookup, runs MarketGapDetector, RiskAnalyzer, and OpportunityScoreAnalyzer,
    and returns a typed FeasibilityScoreResult wrapped in APIResponse.
    """
    db = _get_db()
    found = False
    if db is not None:
        try:
            b_res = db.table("businesses").select("id").eq("id", business_id).execute()
            if b_res.data:
                found = True
        except Exception as e:
            logger.warning(f"Failed to query business in feasibility analyze: {e}")

    if not found and business_id in _OFFLINE_BUSINESSES:
        found = True

    if not found and db is not None:
        raise ResourceNotFoundException("Business", business_id)

    body = req_body or FeasibilityAnalysisRequest()

    # 1. Market Gap Analysis
    market_gap: MarketGapAnalysis = MarketGapDetector.analyze(
        evidence_items=body.evidence_items,
        target_radius_km=body.target_radius_km,
    )

    # 2. Risk Analysis
    risks: RiskAnalysis = RiskAnalyzer.analyze(
        evidence_items=body.evidence_items,
        target_radius_km=body.target_radius_km,
    )

    # 3. Opportunity Score Analysis
    score_result: FeasibilityScoreResult = OpportunityScoreAnalyzer.analyze(
        market_gap=market_gap,
        risks=risks,
        financial=body.financial_simulation,
    )

    return APIResponse(
        success=True,
        data=score_result,
        message="Feasibility analysis completed successfully",
    )
