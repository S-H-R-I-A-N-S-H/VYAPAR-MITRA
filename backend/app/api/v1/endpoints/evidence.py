from typing import List
from fastapi import APIRouter
from app.schemas.common import APIResponse
from app.schemas.evidence import ConflictItem, EvidenceItem
from app.services.conflict_detector import ConflictDetector

router = APIRouter()


@router.post("/detect-conflicts", response_model=APIResponse[List[ConflictItem]])
async def detect_conflicts(evidence_items: List[EvidenceItem]):
    """
    Analyzes primary vs secondary research evidence to identify contradictions and risks.
    """
    conflicts = ConflictDetector.detect_conflicts(evidence_items)
    return APIResponse(
        success=True,
        data=conflicts,
        message=f"Analyzed evidence: {len(conflicts)} conflict(s) surfaced.",
    )
