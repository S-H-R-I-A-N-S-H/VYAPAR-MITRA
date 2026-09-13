from typing import List
from fastapi import APIRouter
from app.adapters.supabase_adapter import supabase_adapter
from app.schemas.common import APIResponse
from app.schemas.schemes import MatchedScheme, SchemeItem, SchemeMatchRequest
from app.services.scheme_matcher import SchemeMatcher
from app.services.semantic_retriever import DEFAULT_SCHEMES_CATALOG

router = APIRouter()


@router.get("/", response_model=APIResponse[List[SchemeItem]])
async def list_schemes():
    """
    Returns active government schemes catalog available in the database or built-in registry.
    """
    client = supabase_adapter.admin_client or supabase_adapter.client
    if client is not None:
        try:
            response = client.table("schemes").select("*").eq("is_active", True).execute()
            if response.data and len(response.data) > 0:
                schemes = [SchemeItem(**row) for row in response.data]
                return APIResponse(
                    success=True,
                    data=schemes,
                    message=f"Retrieved {len(schemes)} active government schemes from database.",
                )
        except Exception as exc:
            pass

    # Fallback to standard verified registry
    fallback_items = [
        SchemeItem(
            id=s["id"],
            scheme_code=s["scheme_code"],
            official_name=s["official_name"],
            authority=s["authority"],
            max_loan_limit=s.get("max_loan_limit"),
            max_subsidy_pct=s.get("max_subsidy_pct", 0.0),
            official_portal_url=s.get("official_portal_url"),
            eligibility_rules=s.get("eligibility_rules", {}),
            is_active=s.get("is_active", True),
        )
        for s in DEFAULT_SCHEMES_CATALOG
    ]
    return APIResponse(
        success=True,
        data=fallback_items,
        message=f"Retrieved {len(fallback_items)} active government schemes (verified registry).",
    )


@router.post("/match", response_model=APIResponse[List[MatchedScheme]])
async def match_schemes(payload: SchemeMatchRequest):
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
