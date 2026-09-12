from datetime import datetime, timezone
import logging
import uuid
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, status

from app.adapters.supabase_adapter import supabase_adapter
from app.core.errors import ResourceNotFoundException
from app.core.security import get_current_user
from app.schemas.common import APIResponse
from app.schemas.evidence import ConflictItem, EvidenceCreate, EvidenceItem
from app.schemas.research import (
    ResearchProjectCreate,
    ResearchProjectResponse,
    ResearchQuestionItem,
)
from app.services.conflict_detector import ConflictDetector, UncertaintyReport
from app.services.prompt_service import PromptService

logger = logging.getLogger(__name__)

router = APIRouter()
conflict_detector = ConflictDetector()
prompt_service = PromptService()

# In-memory stores for sandbox/test mode
_OFFLINE_PROJECTS: Dict[str, Dict[str, Any]] = {}
_OFFLINE_QUESTIONS: Dict[str, List[Dict[str, Any]]] = {}
_OFFLINE_EVIDENCE: Dict[str, List[Dict[str, Any]]] = {}


def _get_db():
    return supabase_adapter.admin_client or supabase_adapter.client


@router.post(
    "/research/projects",
    response_model=APIResponse[ResearchProjectResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create research project for business with auto-generated hypotheses",
)
async def create_research_project(
    proj_in: ResearchProjectCreate,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    db = _get_db()
    now = datetime.now(timezone.utc)
    proj_id = str(uuid.uuid4())

    # Pre-crafted structured research hypotheses across 6 pillars
    base_questions = [
        ("demand", "What is the validated daily volume demand within the target local radius?"),
        ("pricing", "What is the maximum price per unit local consumers and retail stockists are willing to pay?"),
        ("competition", "How many direct and informal competitors operate in this geography, and at what pricing?"),
        ("supplier", "Are raw materials accessible locally without high freight or seasonal supply disruptions?"),
        ("distribution", "Can products be sold directly to local households or are middlemen/distributors required?"),
        ("risk", "What are the primary operational risks (perishability, power outages, license approvals)?"),
    ]

    if db is not None:
        try:
            insert_dict = {
                "id": proj_id,
                "business_id": proj_in.business_id,
                "location_id": proj_in.location_id,
                "status": "ANALYSIS",
                "research_scope": proj_in.research_scope or "local_5km",
                "started_at": now.isoformat(),
                "created_at": now.isoformat(),
                "updated_at": now.isoformat(),
            }
            res = db.table("research_projects").insert(insert_dict).execute()
            if res.data:
                rec = res.data[0]
                # Seed questions
                for cat, q_text in base_questions:
                    db.table("research_questions").insert({
                        "research_project_id": proj_id,
                        "question": q_text,
                        "category": cat,
                        "priority": 1,
                        "status": "open",
                        "created_at": now.isoformat(),
                    }).execute()

                return APIResponse(
                    success=True,
                    data=ResearchProjectResponse(
                        id=str(rec["id"]),
                        business_id=str(rec["business_id"]),
                        location_id=str(rec["location_id"]),
                        status=rec["status"],
                        created_at=datetime.fromisoformat(rec["created_at"]),
                        updated_at=datetime.fromisoformat(rec["updated_at"]),
                    ),
                    message="Research project started with structured hypotheses.",
                )
        except Exception as e:
            logger.warning(f"Database research project insert failed: {e}")

    # Offline sandbox fallback
    proj_record = {
        "id": proj_id,
        "business_id": proj_in.business_id,
        "location_id": proj_in.location_id,
        "status": "ANALYSIS",
        "created_at": now,
        "updated_at": now,
    }
    _OFFLINE_PROJECTS[proj_id] = proj_record
    _OFFLINE_QUESTIONS[proj_id] = [
        {"id": str(uuid.uuid4()), "question": q, "category": c, "status": "open"}
        for c, q in base_questions
    ]
    _OFFLINE_EVIDENCE[proj_id] = []

    return APIResponse(
        success=True,
        data=ResearchProjectResponse(**proj_record),
        message="Research project created (sandbox mode).",
    )


@router.get(
    "/research/projects/{project_id}",
    response_model=APIResponse[ResearchProjectResponse],
    summary="Get research project details",
)
async def get_research_project(
    project_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    db = _get_db()
    if db is not None:
        try:
            res = db.table("research_projects").select("*").eq("id", project_id).execute()
            if res.data:
                rec = res.data[0]
                return APIResponse(
                    success=True,
                    data=ResearchProjectResponse(
                        id=str(rec["id"]),
                        business_id=str(rec["business_id"]),
                        location_id=str(rec["location_id"]),
                        status=rec["status"],
                        created_at=datetime.fromisoformat(rec["created_at"]),
                        updated_at=datetime.fromisoformat(rec["updated_at"]),
                    ),
                )
        except Exception as e:
            logger.warning(f"Database get research project failed: {e}")

    if project_id in _OFFLINE_PROJECTS:
        return APIResponse(success=True, data=ResearchProjectResponse(**_OFFLINE_PROJECTS[project_id]))

    raise ResourceNotFoundException("ResearchProject", project_id)


@router.get(
    "/research/projects/{project_id}/evidence",
    response_model=APIResponse[List[EvidenceItem]],
    summary="Get all evidence items gathered for a research project",
)
async def list_project_evidence(
    project_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    db = _get_db()
    items: List[EvidenceItem] = []

    if db is not None:
        try:
            res = db.table("evidence").select("*").eq("research_project_id", project_id).execute()
            for r in res.data:
                items.append(
                    EvidenceItem(
                        id=str(r["id"]),
                        research_project_id=str(r["research_project_id"]),
                        claim=r["claim"],
                        extracted_value=r.get("extracted_value"),
                        unit=r.get("unit"),
                        source_name=r["source_name"],
                        source_url=r.get("source_url"),
                        source_type=r["source_type"],
                        geography=r.get("geography"),
                        confidence_score=float(r.get("confidence_score") or 0.8),
                        created_at=datetime.fromisoformat(r["created_at"]),
                    )
                )
            return APIResponse(success=True, data=items)
        except Exception as e:
            logger.warning(f"Database get evidence failed: {e}")

    # Fallback to offline store
    for r in _OFFLINE_EVIDENCE.get(project_id, []):
        items.append(EvidenceItem(**r))

    return APIResponse(success=True, data=items)


@router.post(
    "/research/projects/{project_id}/evidence",
    response_model=APIResponse[EvidenceItem],
    status_code=status.HTTP_201_CREATED,
    summary="Add evidence item to research project",
)
async def add_evidence_item(
    project_id: str,
    ev_in: EvidenceCreate,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    db = _get_db()
    now = datetime.now(timezone.utc)
    ev_id = str(uuid.uuid4())

    if db is not None:
        try:
            ins_dict = {
                "id": ev_id,
                "research_project_id": project_id,
                "claim": ev_in.claim,
                "extracted_value": ev_in.extracted_value,
                "unit": ev_in.unit,
                "source_name": ev_in.source_name,
                "source_url": ev_in.source_url,
                "source_type": ev_in.source_type,
                "geography": ev_in.geography,
                "confidence_score": ev_in.confidence_score,
                "created_at": now.isoformat(),
            }
            res = db.table("evidence").insert(ins_dict).execute()
            if res.data:
                r = res.data[0]
                return APIResponse(
                    success=True,
                    data=EvidenceItem(
                        id=str(r["id"]),
                        research_project_id=str(r["research_project_id"]),
                        claim=r["claim"],
                        extracted_value=r.get("extracted_value"),
                        unit=r.get("unit"),
                        source_name=r["source_name"],
                        source_url=r.get("source_url"),
                        source_type=r["source_type"],
                        geography=r.get("geography"),
                        confidence_score=float(r.get("confidence_score") or 0.8),
                        created_at=datetime.fromisoformat(r["created_at"]),
                    ),
                    message="Evidence recorded successfully.",
                )
        except Exception as e:
            logger.warning(f"Database insert evidence failed: {e}")

    ev_record = {
        "id": ev_id,
        "research_project_id": project_id,
        "claim": ev_in.claim,
        "extracted_value": ev_in.extracted_value,
        "unit": ev_in.unit,
        "source_name": ev_in.source_name,
        "source_url": ev_in.source_url,
        "source_type": ev_in.source_type,
        "geography": ev_in.geography,
        "confidence_score": ev_in.confidence_score,
        "created_at": now,
    }
    if project_id not in _OFFLINE_EVIDENCE:
        _OFFLINE_EVIDENCE[project_id] = []
    _OFFLINE_EVIDENCE[project_id].append(ev_record)

    return APIResponse(
        success=True,
        data=EvidenceItem(**ev_record),
        message="Evidence recorded (sandbox mode).",
    )


@router.get(
    "/research/projects/{project_id}/conflicts",
    response_model=APIResponse[List[ConflictItem]],
    summary="Detect and resolve contradictions between secondary research and primary field data",
)
async def get_project_conflicts(
    project_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    ev_list_res = await list_project_evidence(project_id, current_user)
    evidence_items = ev_list_res.data or []

    conflicts = await conflict_detector.analyze_and_resolve(evidence_items)
    return APIResponse(
        success=True,
        data=conflicts,
        message=f"Detected {len(conflicts)} contradiction(s) between macro and local evidence.",
    )


@router.get(
    "/research/projects/{project_id}/uncertainty",
    response_model=APIResponse[UncertaintyReport],
    summary="Generate evidence completeness and uncertainty score",
)
async def get_project_uncertainty(
    project_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    ev_list_res = await list_project_evidence(project_id, current_user)
    evidence_items = ev_list_res.data or []

    report = await conflict_detector.generate_uncertainty_report(evidence_items)
    return APIResponse(
        success=True,
        data=report,
        message="Uncertainty analysis generated.",
    )
