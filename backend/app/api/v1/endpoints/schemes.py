from typing import List
from fastapi import APIRouter
from app.schemas.common import APIResponse
from app.schemas.schemes import MatchedScheme, SchemeMatchRequest
from app.services.scheme_matcher import SchemeMatcher

router = APIRouter()


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
