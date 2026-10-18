from typing import List
from fastapi import APIRouter, Depends
from app.adapters.supabase_adapter import supabase_adapter
from app.core.security import AuthenticatedUser, get_current_user
from app.schemas.common import APIResponse
from app.schemas.schemes import MatchedScheme, SchemeItem, SchemeMatchRequest
from app.services.scheme_matcher import SchemeMatcher

router = APIRouter()


import logging

logger = logging.getLogger(__name__)

DEFAULT_SCHEMES: List[SchemeItem] = [
    SchemeItem(
        id="scheme-pmegp",
        scheme_code="PMEGP",
        official_name="Prime Minister's Employment Generation Programme",
        authority="Khadi and Village Industries Commission (KVIC) / MSME",
        max_loan_limit=5000000.00,
        max_subsidy_pct=35.00,
        official_portal_url="https://www.kviconline.gov.in/pmegpeportal/",
        eligibility_rules={
            "min_age": 18,
            "rural_subsidy_special": 35.0,
            "rural_subsidy_general": 25.0,
            "own_contribution_special_pct": 5,
            "own_contribution_general_pct": 10,
        },
        is_active=True,
    ),
    SchemeItem(
        id="scheme-mudra-shishu",
        scheme_code="MUDRA_SHISHU",
        official_name="Pradhan Mantri MUDRA Yojana - Shishu",
        authority="MUDRA / Department of Financial Services",
        max_loan_limit=50000.00,
        max_subsidy_pct=0.00,
        official_portal_url="https://www.mudra.org.in/",
        eligibility_rules={
            "max_amount": 50000.00,
            "collateral_required": False,
            "target_segment": "micro_startups",
        },
        is_active=True,
    ),
    SchemeItem(
        id="scheme-mudra-kishore",
        scheme_code="MUDRA_KISHORE",
        official_name="Pradhan Mantri MUDRA Yojana - Kishore",
        authority="MUDRA / Department of Financial Services",
        max_loan_limit=500000.00,
        max_subsidy_pct=0.00,
        official_portal_url="https://www.mudra.org.in/",
        eligibility_rules={
            "min_amount": 50001.00,
            "max_amount": 500000.00,
            "collateral_required": False,
        },
        is_active=True,
    ),
    SchemeItem(
        id="scheme-mudra-tarun",
        scheme_code="MUDRA_TARUN",
        official_name="Pradhan Mantri MUDRA Yojana - Tarun",
        authority="MUDRA / Department of Financial Services",
        max_loan_limit=1000000.00,
        max_subsidy_pct=0.00,
        official_portal_url="https://www.mudra.org.in/",
        eligibility_rules={
            "min_amount": 500001.00,
            "max_amount": 1000000.00,
            "collateral_required": False,
        },
        is_active=True,
    ),
    SchemeItem(
        id="scheme-standup-india",
        scheme_code="STANDUP_INDIA",
        official_name="Stand-Up India Scheme",
        authority="SIDBI / Ministry of Finance",
        max_loan_limit=10000000.00,
        max_subsidy_pct=0.00,
        official_portal_url="https://www.standupmitra.in/",
        eligibility_rules={
            "min_amount": 1000000.00,
            "max_amount": 10000000.00,
            "eligible_categories": ["sc", "st", "woman"],
            "greenfield_only": True,
        },
        is_active=True,
    ),
]


@router.get("/", response_model=APIResponse[List[SchemeItem]])
async def list_schemes(current_user: AuthenticatedUser = Depends(get_current_user)):  # FIX HIGH-4a
    """
    Returns active government schemes catalog available in the database.
    Degrades gracefully to canonical seed catalog when database is unconfigured or offline.
    """
    client = supabase_adapter.admin_client or supabase_adapter.client
    if not client:
        return APIResponse(
            success=True,
            data=DEFAULT_SCHEMES,
            message=f"Retrieved {len(DEFAULT_SCHEMES)} active government schemes (offline catalog).",
        )
    try:
        response = client.table("schemes").select("*").eq("is_active", True).execute()
        schemes = [SchemeItem(**row) for row in response.data] if response.data else DEFAULT_SCHEMES
        return APIResponse(
            success=True,
            data=schemes,
            message=f"Retrieved {len(schemes)} active government schemes.",
        )
    except Exception as exc:
        logger.warning(
            f"Failed to query live schemes table ({exc}); degrading gracefully to canonical default catalog."
        )
        return APIResponse(
            success=True,
            data=DEFAULT_SCHEMES,
            message=f"Retrieved {len(DEFAULT_SCHEMES)} active government schemes (offline fallback).",
        )


@router.post("/match", response_model=APIResponse[List[MatchedScheme]])
async def match_schemes(
    payload: SchemeMatchRequest,
    current_user: AuthenticatedUser = Depends(get_current_user),  # FIX HIGH-4a
):

    """
    Evaluates government scheme eligibility based on project parameters,
    capital requirements, and optional affirmative category consent.
    """
    matches = SchemeMatcher.evaluate(payload)
    return APIResponse(
        success=True,
        data=matches,
        message=f"Found {len(matches)} eligible or applicable government schemes.",
    )

