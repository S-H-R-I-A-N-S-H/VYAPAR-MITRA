from typing import List
from fastapi import APIRouter, Depends
from app.adapters.supabase_adapter import supabase_adapter
from app.core.security import AuthenticatedUser, get_current_user
from app.schemas.common import APIResponse
from app.schemas.schemes import MatchedScheme, SchemeItem, SchemeMatchRequest
from app.services.scheme_matcher import SchemeMatcher

router = APIRouter()


@router.get("/", response_model=APIResponse[List[SchemeItem]])
async def list_schemes(current_user: AuthenticatedUser = Depends(get_current_user)):  # FIX HIGH-4a
    """
    Returns active government schemes catalog available in the database.
    """
    client = supabase_adapter.admin_client or supabase_adapter.client
    if not client:
        return APIResponse(
            success=True,
            data=[],
            message="Database client unavailable. Returning empty catalog.",
        )
    try:
        response = client.table("schemes").select("*").eq("is_active", True).execute()
        schemes = [SchemeItem(**row) for row in response.data]
        return APIResponse(
            success=True,
            data=schemes,
            message=f"Retrieved {len(schemes)} active government schemes.",
        )
    except Exception as exc:
        return APIResponse(
            success=False,
            data=[],
            message=f"Failed to fetch schemes: {str(exc)}",
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

