from datetime import datetime, timezone
import logging
import uuid
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, status

from app.adapters.mappls_adapter import MapplsAdapter
from app.adapters.supabase_adapter import supabase_adapter
from app.core.config import settings
from app.core.errors import (
    ForbiddenOperationException,
    ResourceNotFoundException,
    ServiceUnavailableException,
)
from app.core.security import AuthenticatedUser, get_current_user
from app.utils import (
    extract_user_id,
    get_user_entrepreneur_ids,
    is_valid_uuid,
    require_db,
    should_use_offline_fallback,
    verify_business_ownership,
    verify_research_project_ownership,
)
from app.schemas.common import APIResponse, PaginationParams

from app.schemas.evidence import ConflictItem, EvidenceCreate, EvidenceItem
from app.schemas.research import (
    ResearchProjectCreate,
    ResearchProjectResponse,
    ResearchQuestionItem,
)
from app.services.conflict_detector import ConflictDetector, UncertaintyReport
from app.services.prompt_service import PromptService
from app.services.smart_research_service import SmartResearchService

logger = logging.getLogger(__name__)

router = APIRouter()
conflict_detector = ConflictDetector()
prompt_service = PromptService()
mappls_adapter = MapplsAdapter()
smart_research_service = SmartResearchService()

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
    verify_business_ownership(db, proj_in.business_id, current_user)
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
                        "id": str(uuid.uuid4()),
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
                        location_id=str(rec["location_id"]) if rec.get("location_id") else None,
                        status=rec["status"],
                        created_at=datetime.fromisoformat(rec["created_at"]),
                        updated_at=datetime.fromisoformat(rec["updated_at"]),
                    ),
                    message="Research project started with structured hypotheses.",
                )
        except Exception as e:
            logger.warning(f"Database research project insert failed: {e}")
            if settings.ENVIRONMENT == "production":
                raise ServiceUnavailableException("Failed to persist research project.")

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
    "/research/projects",
    response_model=APIResponse[List[ResearchProjectResponse]],
    summary="List all research projects for authenticated entrepreneur",
)
async def list_research_projects(
    business_id: Optional[str] = None,
    pagination: PaginationParams = Depends(),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    user_id = extract_user_id(current_user)
    db = _get_db()
    results: List[ResearchProjectResponse] = []

    if db is not None:
        try:
            ent_ids = get_user_entrepreneur_ids(db, user_id)
            if ent_ids:
                biz_res = db.table("businesses").select("id").in_("entrepreneur_id", ent_ids).execute()
                allowed_biz_ids = [str(b["id"]) for b in (biz_res.data or [])]
                if business_id:
                    allowed_biz_ids = [b for b in allowed_biz_ids if b == business_id]

                if allowed_biz_ids:
                    start, end = pagination.range_offset()
                    p_res = (
                        db.table("research_projects")
                        .select("*, locations(*), businesses(*)")
                        .in_("business_id", allowed_biz_ids)
                        .order("created_at", desc=True)
                        .range(start, end)
                        .execute()
                    )
                    for rec in (p_res.data or []):
                        created_at = rec.get("created_at")
                        if isinstance(created_at, str):
                            created_at = datetime.fromisoformat(created_at)
                        updated_at = rec.get("updated_at")
                        if isinstance(updated_at, str):
                            updated_at = datetime.fromisoformat(updated_at)
                        results.append(
                            ResearchProjectResponse(
                                id=str(rec["id"]),
                                business_id=str(rec["business_id"]),
                                location_id=str(rec["location_id"]) if rec.get("location_id") else None,
                                status=rec.get("status", "ANALYSIS"),
                                created_at=created_at or datetime.now(timezone.utc),
                                updated_at=updated_at or datetime.now(timezone.utc),
                            )
                        )
                    return APIResponse(success=True, data=results)
        except Exception as e:
            logger.warning(f"Database list research projects failed: {e}")

    for p_id, rec in _OFFLINE_PROJECTS.items():
        if not business_id or rec.get("business_id") == business_id:
            results.append(ResearchProjectResponse(**rec))

    paginated_fallback = results[pagination.offset : pagination.offset + pagination.limit]
    return APIResponse(success=True, data=paginated_fallback)


@router.get(
    "/research/projects/{project_id}",
    response_model=APIResponse[ResearchProjectResponse],
    summary="Get research project details",
)
async def get_research_project(
    project_id: str,
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    db = _get_db()
    rec = verify_research_project_ownership(db, project_id, current_user)
    created_at = rec.get("created_at")
    if isinstance(created_at, str):
        created_at = datetime.fromisoformat(created_at)
    updated_at = rec.get("updated_at")
    if isinstance(updated_at, str):
        updated_at = datetime.fromisoformat(updated_at)

    return APIResponse(
        success=True,
        data=ResearchProjectResponse(
            id=str(rec["id"]),
            business_id=str(rec["business_id"]),
            location_id=str(rec["location_id"]) if rec.get("location_id") else None,
            status=rec.get("status", "ANALYSIS"),
            created_at=created_at or datetime.now(timezone.utc),
            updated_at=updated_at or datetime.now(timezone.utc),
        ),
    )


@router.get(
    "/research/projects/{project_id}/evidence",
    response_model=APIResponse[List[EvidenceItem]],
    summary="Get all evidence items gathered for a research project",
)
async def list_project_evidence(
    project_id: str,
    current_user: AuthenticatedUser = Depends(get_current_user),
    pagination: Optional[PaginationParams] = None,
):
    if pagination is None:
        pagination = PaginationParams()
    db = _get_db()
    verify_research_project_ownership(db, project_id, current_user)
    items: List[EvidenceItem] = []

    if db is not None:
        try:
            start, end = pagination.range_offset()
            res = (
                db.table("evidence")
                .select("*")
                .eq("research_project_id", project_id)
                .order("created_at", desc=True)
                .range(start, end)
                .execute()
            )
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
            if items:
                return APIResponse(success=True, data=items)
        except Exception as e:
            logger.warning(f"Database get evidence failed: {e}")

    # Fallback to offline store
    for r in _OFFLINE_EVIDENCE.get(project_id, []):
        items.append(EvidenceItem(**r))

    paginated_fallback = items[pagination.offset : pagination.offset + pagination.limit]
    return APIResponse(success=True, data=paginated_fallback)



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
    verify_research_project_ownership(db, project_id, current_user)
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
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    ev_list_res = await list_project_evidence(project_id=project_id, current_user=current_user)
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
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    ev_list_res = await list_project_evidence(project_id=project_id, current_user=current_user)
    evidence_items = ev_list_res.data or []

    report = await conflict_detector.generate_uncertainty_report(evidence_items)
    return APIResponse(
        success=True,
        data=report,
        message="Uncertainty analysis generated.",
    )


@router.post(
    "/research/projects/{project_id}/discover-competitors",
    summary="Ground project research by discovering actual nearby competitors via Mappls",
)
async def discover_project_competitors(
    project_id: str,
    category: Optional[str] = None,
    radius_km: float = 5.0,
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    # Verify project exists
    await get_research_project(project_id, current_user)
    db = _get_db()
    now = datetime.now(timezone.utc)

    # Resolve locality / coordinates
    lat = 18.5204
    lon = 73.8567
    cat = category or "General Enterprise"

    if db is not None and is_valid_uuid(project_id):
        try:
            proj_res = db.table("research_projects").select("*, locations(*), businesses(*)").eq("id", project_id).execute()
            if proj_res.data:
                p = proj_res.data[0]
                loc = p.get("locations") or {}
                biz = p.get("businesses") or {}
                if loc.get("latitude") and loc.get("longitude"):
                    lat = float(loc["latitude"])
                    lon = float(loc["longitude"])
                if biz.get("name") and not category:
                    cat = biz["name"]
        except Exception as e:
            logger.warning(f"Error reading project location/business from db: {e}")

    competitors = await mappls_adapter.find_nearby_competitors(
        latitude=lat,
        longitude=lon,
        category=cat,
        radius_km=radius_km,
    )

    # Record as MAPPLS_POI EvidenceItem
    comp_names = [c["name"] for c in competitors[:3]]
    claim_text = (
        f"{len(competitors)} direct competitors registered locally: {', '.join(comp_names)}."
        if competitors
        else f"Zero registered competitors found within {radius_km}km via Mappls."
    )

    ev_id = str(uuid.uuid4())
    ev_item = EvidenceItem(
        id=ev_id,
        research_project_id=project_id,
        claim=claim_text,
        extracted_value=str(len(competitors)),
        unit="competitors",
        source_name="Mappls GeoPOI",
        source_url="https://atlas.mappls.com",
        source_type="MAPPLS_POI",
        confidence_score=0.90,
        created_at=now,
    )

    if db is not None:
        try:
            db.table("evidence").insert({
                "id": ev_id,
                "research_project_id": project_id,
                "claim": claim_text,
                "extracted_value": str(len(competitors)),
                "unit": "competitors",
                "source_name": "Mappls GeoPOI",
                "source_url": "https://atlas.mappls.com",
                "source_type": "MAPPLS_POI",
                "confidence_score": 0.90,
                "created_at": now.isoformat(),
            }).execute()
        except Exception as e:
            logger.warning(f"Failed to insert Mappls evidence in db: {e}")

    if project_id not in _OFFLINE_EVIDENCE:
        _OFFLINE_EVIDENCE[project_id] = []
    _OFFLINE_EVIDENCE[project_id].append(ev_item.model_dump())

    return APIResponse(
        success=True,
        data={
            "project_id": project_id,
            "category": cat,
            "competitor_count": len(competitors),
            "competitors": competitors,
            "evidence_item": ev_item,
        },
        message=f"Discovered {len(competitors)} local competitors and logged to research evidence.",
    )


@router.post(
    "/research/projects/{project_id}/synthesize-secondary-research",
    summary="Synthesize live multi-pillar secondary research using Google Search Grounding and Mappls POI",
)
async def synthesize_project_secondary_research(
    project_id: str,
    radius_km: float = 5.0,
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    proj_res = await get_research_project(project_id, current_user)
    db = _get_db()

    biz_name = "Enterprise"
    biz_domain = "General"
    locality = "Local Area"
    district = "District"
    state = "State"
    lat = 22.9772
    lon = 75.8078

    if db is not None and is_valid_uuid(project_id):
        try:
            p_data = db.table("research_projects").select("*, locations(*), businesses(*)").eq("id", project_id).execute()
            if p_data.data:
                p = p_data.data[0]
                loc = p.get("locations") or {}
                biz = p.get("businesses") or {}
                biz_name = biz.get("name") or biz.get("product_or_service") or biz_name
                biz_domain = biz.get("domain") or biz_domain
                locality = loc.get("town_or_village") or locality
                district = loc.get("district") or district
                state = loc.get("state") or state
                if loc.get("latitude") and loc.get("longitude"):
                    lat = float(loc["latitude"])
                    lon = float(loc["longitude"])
        except Exception as e:
            logger.warning(f"Failed to load project details for research synthesis: {e}")

    if biz_name == "Enterprise":
        for b_id, b_rec in _OFFLINE_PROJECTS.items():
            if b_id == project_id:
                biz_id = b_rec.get("business_id")
                from app.api.v1.endpoints.businesses import _OFFLINE_BUSINESSES
                biz_obj = _OFFLINE_BUSINESSES.get(biz_id, {})
                biz_name = biz_obj.get("name", "Enterprise")
                biz_domain = biz_obj.get("domain", "General")

    research_result = await smart_research_service.execute_smart_research(
        project_id=project_id,
        business_name=biz_name,
        domain=biz_domain,
        locality=locality,
        district=district,
        state=state,
        latitude=lat,
        longitude=lon,
        radius_km=radius_km,
    )

    ev_items = research_result["evidence_items"]
    if db is not None:
        try:
            for ev in ev_items:
                db.table("evidence").insert({
                    "id": ev.id,
                    "research_project_id": project_id,
                    "claim": ev.claim,
                    "extracted_value": ev.extracted_value,
                    "unit": ev.unit,
                    "source_name": ev.source_name,
                    "source_url": ev.source_url,
                    "source_type": ev.source_type,
                    "geography": ev.geography,
                    "confidence_score": ev.confidence_score,
                    "created_at": ev.created_at.isoformat(),
                }).execute()
        except Exception as e:
            logger.warning(f"Error persisting synthesized evidence in db: {e}")

    if project_id not in _OFFLINE_EVIDENCE:
        _OFFLINE_EVIDENCE[project_id] = []
    for ev in ev_items:
        _OFFLINE_EVIDENCE[project_id].append(ev.model_dump())

    return APIResponse(
        success=True,
        data={
            "project_id": project_id,
            "business_name": biz_name,
            "domain": biz_domain,
            "locality": locality,
            "district": district,
            "state": state,
            "competitor_count": research_result["competitor_count"],
            "competitors": research_result["competitors"],
            "evidence_count": len(ev_items),
            "evidence_items": [ev.model_dump() for ev in ev_items],
            "pipeline_steps": research_result["pipeline_steps"],
            "grounded_sources": research_result["grounded_sources"],
            "search_grounded": research_result["search_grounded"],
        },
        message=f"Synthesized live secondary research for {biz_name} in {district}.",
    )


