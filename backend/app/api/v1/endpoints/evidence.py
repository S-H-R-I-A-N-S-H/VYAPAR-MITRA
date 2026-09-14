from typing import List
from fastapi import APIRouter, Depends
from app.core.security import AuthenticatedUser, get_current_user
from app.schemas.common import APIResponse
from app.schemas.evidence import ConflictItem, EvidenceItem
from app.services.conflict_detector import ConflictDetector

router = APIRouter()


@router.post("/detect-conflicts", response_model=APIResponse[List[ConflictItem]])
async def detect_conflicts(
    evidence_items: List[EvidenceItem],
    current_user: AuthenticatedUser = Depends(get_current_user),  # FIX HIGH-4b: was unauthenticated
):
    """
    Analyzes primary vs secondary research evidence to identify contradictions and risks.
    """
    conflicts = ConflictDetector.detect_conflicts(evidence_items)
    return APIResponse(
        success=True,
        data=conflicts,
        message=f"Analyzed evidence: {len(conflicts)} conflict(s) surfaced.",
    )
