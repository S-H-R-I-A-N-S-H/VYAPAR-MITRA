from datetime import datetime, timezone
import logging
import uuid
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, status

from app.adapters.supabase_adapter import supabase_adapter
from app.api.v1.endpoints.research import _OFFLINE_EVIDENCE
from app.core.errors import ResourceNotFoundException
from app.core.security import get_current_user
from app.schemas.common import APIResponse
from app.utils import verify_research_project_ownership, verify_survey_ownership
from app.schemas.surveys import (
    SurveyCreate,
    SurveyModelResponse,
    SurveyQuestionInput,
    SurveyResponseCreate,
    SurveyResponseItem,
)

logger = logging.getLogger(__name__)

router = APIRouter()

_OFFLINE_SURVEYS: Dict[str, Dict[str, Any]] = {}
_OFFLINE_RESPONSES: Dict[str, List[Dict[str, Any]]] = {}


def _get_db():
    return supabase_adapter.admin_client or supabase_adapter.client


@router.post(
    "/surveys",
    response_model=APIResponse[SurveyModelResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create primary field survey for a research project",
)
async def create_survey(
    survey_in: SurveyCreate,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    db = _get_db()
    verify_research_project_ownership(db, survey_in.research_project_id, current_user)
    now = datetime.now(timezone.utc)
    survey_id = str(uuid.uuid4())

    if db is not None:
        try:
            ins_survey = {
                "id": survey_id,
                "research_project_id": survey_in.research_project_id,
                "title": survey_in.title,
                "target_respondent_type": survey_in.target_respondent_type,
                "created_at": now.isoformat(),
            }
            res = db.table("surveys").insert(ins_survey).execute()
            if res.data:
                for idx, q in enumerate(survey_in.questions):
                    db.table("survey_questions").insert({
                        "id": str(uuid.uuid4()),
                        "survey_id": survey_id,
                        "question_text": q.question_text,
                        "question_type": q.question_type,
                        "options": q.options,
                        "sort_order": idx,
                    }).execute()

                return APIResponse(
                    success=True,
                    data=SurveyModelResponse(
                        id=survey_id,
                        research_project_id=survey_in.research_project_id,
                        title=survey_in.title,
                        target_respondent_type=survey_in.target_respondent_type,
                        questions=survey_in.questions,
                        created_at=now,
                    ),
                    message="Field survey generated.",
                )
        except Exception as e:
            logger.warning(f"Database survey insert failed: {e}")

    # Offline sandbox
    survey_record = {
        "id": survey_id,
        "research_project_id": survey_in.research_project_id,
        "title": survey_in.title,
        "target_respondent_type": survey_in.target_respondent_type,
        "questions": survey_in.questions,
        "created_at": now,
    }
    _OFFLINE_SURVEYS[survey_id] = survey_record
    _OFFLINE_RESPONSES[survey_id] = []

    return APIResponse(
        success=True,
        data=SurveyModelResponse(**survey_record),
        message="Field survey generated (sandbox mode).",
    )


@router.get(
    "/surveys/{survey_id}",
    response_model=APIResponse[SurveyModelResponse],
    summary="Get survey with questions",
)
async def get_survey(
    survey_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    db = _get_db()
    verify_survey_ownership(db, survey_id, current_user)
    if db is not None:
        try:
            res = db.table("surveys").select("*").eq("id", survey_id).execute()
            if res.data:
                rec = res.data[0]
                q_res = db.table("survey_questions").select("*").eq("survey_id", survey_id).order("sort_order").execute()
                questions = [
                    SurveyQuestionInput(
                        id=str(q["id"]),
                        question_text=q["question_text"],
                        question_type=q["question_type"],
                        options=q.get("options") or [],
                        sort_order=q.get("sort_order") or 0,
                    )
                    for q in q_res.data
                ]
                return APIResponse(
                    success=True,
                    data=SurveyModelResponse(
                        id=str(rec["id"]),
                        research_project_id=str(rec["research_project_id"]),
                        title=rec["title"],
                        target_respondent_type=rec["target_respondent_type"],
                        questions=questions,
                        created_at=datetime.fromisoformat(rec["created_at"]),
                    ),
                )
        except Exception as e:
            logger.warning(f"Database get survey failed: {e}")

    if survey_id in _OFFLINE_SURVEYS:
        return APIResponse(success=True, data=SurveyModelResponse(**_OFFLINE_SURVEYS[survey_id]))

    raise ResourceNotFoundException("Survey", survey_id)


@router.post(
    "/surveys/{survey_id}/responses",
    response_model=APIResponse[SurveyResponseItem],
    status_code=status.HTTP_201_CREATED,
    summary="Submit field survey response and automatically extract primary field evidence",
)
async def submit_survey_response(
    survey_id: str,
    resp_in: SurveyResponseCreate,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    db = _get_db()
    verify_survey_ownership(db, survey_id, current_user)
    now = datetime.now(timezone.utc)
    resp_id = str(uuid.uuid4())

    proj_id = None
    survey_title = "Field Survey"

    if db is not None:
        try:
            # 1. Lookup project ID from survey
            s_res = db.table("surveys").select("research_project_id, title").eq("id", survey_id).execute()
            if s_res.data:
                proj_id = str(s_res.data[0]["research_project_id"])
                survey_title = s_res.data[0]["title"]

            # 2. Insert survey response
            db.table("survey_responses").insert({
                "id": resp_id,
                "survey_id": survey_id,
                "respondent_identifier": resp_in.respondent_identifier,
                "answers": resp_in.answers,
                "collector_notes": resp_in.collector_notes,
                "created_at": now.isoformat(),
            }).execute()

            # 3. If primary claim extracted, insert directly into evidence table
            if proj_id and resp_in.extracted_claim:
                db.table("evidence").insert({
                    "id": str(uuid.uuid4()),
                    "research_project_id": proj_id,
                    "claim": resp_in.extracted_claim,
                    "extracted_value": resp_in.extracted_value,
                    "unit": resp_in.unit,
                    "source_name": f"{survey_title} ({resp_in.respondent_identifier or 'Anonymous'})",
                    "source_type": "FIELD_PRIMARY",
                    "confidence_score": 0.88,
                    "created_at": now.isoformat(),
                }).execute()

            return APIResponse(
                success=True,
                data=SurveyResponseItem(
                    id=resp_id,
                    survey_id=survey_id,
                    respondent_identifier=resp_in.respondent_identifier,
                    answers=resp_in.answers,
                    collector_notes=resp_in.collector_notes,
                    created_at=now,
                ),
                message="Survey response recorded and primary evidence extracted.",
            )
        except Exception as e:
            logger.warning(f"Database survey response insert failed: {e}")

    # Offline/sandbox fallback
    if survey_id in _OFFLINE_SURVEYS:
        proj_id = _OFFLINE_SURVEYS[survey_id]["research_project_id"]
        survey_title = _OFFLINE_SURVEYS[survey_id]["title"]

    resp_item = {
        "id": resp_id,
        "survey_id": survey_id,
        "respondent_identifier": resp_in.respondent_identifier,
        "answers": resp_in.answers,
        "collector_notes": resp_in.collector_notes,
        "created_at": now,
    }
    if survey_id not in _OFFLINE_RESPONSES:
        _OFFLINE_RESPONSES[survey_id] = []
    _OFFLINE_RESPONSES[survey_id].append(resp_item)

    if proj_id and resp_in.extracted_claim:
        ev_rec = {
            "id": str(uuid.uuid4()),
            "research_project_id": proj_id,
            "claim": resp_in.extracted_claim,
            "extracted_value": resp_in.extracted_value,
            "unit": resp_in.unit,
            "source_name": f"{survey_title} ({resp_in.respondent_identifier or 'Anonymous'})",
            "source_url": None,
            "source_type": "FIELD_PRIMARY",
            "geography": None,
            "confidence_score": 0.88,
            "created_at": now,
        }
        if proj_id not in _OFFLINE_EVIDENCE:
            _OFFLINE_EVIDENCE[proj_id] = []
        _OFFLINE_EVIDENCE[proj_id].append(ev_rec)

    return APIResponse(
        success=True,
        data=SurveyResponseItem(**resp_item),
        message="Survey response recorded (sandbox mode).",
    )
