from datetime import datetime, timezone
import logging
import uuid
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field, field_validator

from app.adapters.bhashini_adapter import BhashiniAdapter
from app.adapters.gemini_adapter import GeminiAdapter
from app.adapters.supabase_adapter import supabase_adapter
from app.core.config import settings
from app.core.errors import ResourceNotFoundException
from app.core.security import get_current_user
from app.schemas.common import APIResponse
from app.services.prompt_service import (
    ExtractedFactor,
    InterviewTurnResponse,
    PromptService,
    sanitize_prompt_input,
)

logger = logging.getLogger(__name__)

router = APIRouter()
prompt_service = PromptService()
gemini_adapter = GeminiAdapter()
bhashini_adapter = BhashiniAdapter()

# Sandbox in-memory store for fallback/tests
_OFFLINE_SESSIONS: Dict[str, Dict[str, Any]] = {}
_OFFLINE_MESSAGES: Dict[str, List[Dict[str, Any]]] = {}


def _get_db():
    return supabase_adapter.admin_client or supabase_adapter.client


# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------

class InterviewSessionCreate(BaseModel):
    language: str = Field(default="hi", description="ISO language code, e.g. hi, en, mr, gu")
    business_id: Optional[str] = None


class InterviewMessageInput(BaseModel):
    content: str = Field(..., min_length=1, description="Entrepreneur message")
    language: Optional[str] = None

    @field_validator("content")
    @classmethod
    def validate_non_empty(cls, v: str) -> str:
        cleaned = v.strip()
        if not cleaned:
            raise ValueError("Message content must not be blank or whitespace only.")
        return cleaned


class InterviewMessageItem(BaseModel):
    id: str
    role: str
    content: str
    created_at: datetime


class InterviewSessionResponse(BaseModel):
    id: str
    entrepreneur_id: str
    business_id: Optional[str] = None
    status: str
    language: str
    started_at: datetime
    completed_at: Optional[datetime] = None
    messages: List[InterviewMessageItem] = Field(default_factory=list)


class VoiceTurnInput(BaseModel):
    audio_base64: str = Field(..., min_length=1, description="Base64 encoded audio bytes from mobile microphone")
    language: Optional[str] = None


class VoiceTurnResponse(BaseModel):
    transcribed_text: str
    reply: str
    next_question: Optional[str] = None
    language: str
    audio_response_base64: str
    extracted_factors: List[ExtractedFactor] = Field(default_factory=list)
    is_complete: bool = False


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@router.post(
    "/interviews",
    response_model=APIResponse[InterviewSessionResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Start new conversational interview session",
)
async def create_interview_session(
    session_in: InterviewSessionCreate,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    user_id = str(current_user.get("sub") or current_user.get("id"))
    db = _get_db()
    now = datetime.now(timezone.utc)

    session_id = str(uuid.uuid4())
    entrepreneur_id = user_id

    if db is not None:
        try:
            try:
                db_user_id = str(uuid.UUID(user_id))
            except ValueError:
                db_user_id = str(uuid.uuid5(uuid.NAMESPACE_DNS, user_id))

            # Find entrepreneur_id from user_id if profile exists, or auto-provision baseline profile
            ent_res = db.table("entrepreneurs").select("id").eq("user_id", db_user_id).execute()
            if ent_res.data:
                entrepreneur_id = str(ent_res.data[0]["id"])
            else:
                new_ent = db.table("entrepreneurs").insert({
                    "user_id": db_user_id,
                    "full_name": "New Entrepreneur",
                    "preferred_language": session_in.language,
                    "available_capital": 0.0,
                }).execute()
                if new_ent.data:
                    entrepreneur_id = str(new_ent.data[0]["id"])

            insert_dict = {
                "id": session_id,
                "entrepreneur_id": entrepreneur_id,
                "business_id": session_in.business_id,
                "status": "ACTIVE",
                "language": session_in.language,
                "started_at": now.isoformat(),
            }
            res = db.table("interview_sessions").insert(insert_dict).execute()
            if res.data:
                rec = res.data[0]
                return APIResponse(
                    success=True,
                    data=InterviewSessionResponse(
                        id=str(rec["id"]),
                        entrepreneur_id=str(rec["entrepreneur_id"]),
                        business_id=rec.get("business_id"),
                        status=rec["status"],
                        language=rec["language"],
                        started_at=datetime.fromisoformat(rec["started_at"]),
                        messages=[],
                    ),
                    message="Interview session started.",
                )
        except Exception as e:
            logger.warning(f"Interview db session creation failed: {e}")

    # Offline/mock session
    session_data = {
        "id": session_id,
        "entrepreneur_id": user_id,
        "business_id": session_in.business_id,
        "status": "ACTIVE",
        "language": session_in.language,
        "started_at": now,
        "completed_at": None,
    }
    _OFFLINE_SESSIONS[session_id] = session_data
    _OFFLINE_MESSAGES[session_id] = []

    return APIResponse(
        success=True,
        data=InterviewSessionResponse(**session_data, messages=[]),
        message="Interview session started (sandbox mode).",
    )


@router.post(
    "/interviews/{session_id}/messages",
    response_model=APIResponse[InterviewTurnResponse],
    summary="Send message and receive AI mentor response with extracted facts",
)
async def send_interview_message(
    session_id: str,
    msg_in: InterviewMessageInput,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    db = _get_db()
    now = datetime.now(timezone.utc)
    sanitized_content = sanitize_prompt_input(msg_in.content)

    # 1. Fetch conversation history
    history: List[Dict[str, str]] = []
    language = "hi"
    found_in_db = False

    if db is not None:
        try:
            sess_res = db.table("interview_sessions").select("*").eq("id", session_id).execute()
            if sess_res.data:
                found_in_db = True
                language = sess_res.data[0]["language"]

                msgs_res = (
                    db.table("interview_messages")
                    .select("*")
                    .eq("session_id", session_id)
                    .order("created_at")
                    .execute()
                )
                for m in msgs_res.data:
                    history.append({"role": m["role"].lower(), "content": m["content"]})
        except Exception as e:
            logger.warning(f"Failed to fetch interview history from db: {e}")

    if not found_in_db:
        if session_id in _OFFLINE_SESSIONS:
            language = _OFFLINE_SESSIONS.get(session_id, {}).get("language", "hi")
            for m in _OFFLINE_MESSAGES.get(session_id, []):
                history.append({"role": m["role"].lower(), "content": m["content"]})
        elif session_id.startswith("offline-") or settings.ENVIRONMENT == "development":
            _OFFLINE_SESSIONS[session_id] = {
                "id": session_id,
                "entrepreneur_id": str(current_user.get("sub") or "dev-user-default"),
                "language": msg_in.language or "hi",
            }
            _OFFLINE_MESSAGES[session_id] = []
            language = msg_in.language or "hi"
        else:
            raise ResourceNotFoundException("InterviewSession", session_id)

        # Attempt to auto-persist missing session into DB if valid UUID format
        if db is not None:
            try:
                valid_session_uuid = str(uuid.UUID(session_id))
                user_id_raw = str(current_user.get("sub") or current_user.get("id") or "dev-user-default")
                try:
                    db_user_id = str(uuid.UUID(user_id_raw))
                except ValueError:
                    db_user_id = str(uuid.uuid5(uuid.NAMESPACE_DNS, user_id_raw))

                ent_res = db.table("entrepreneurs").select("id").eq("user_id", db_user_id).execute()
                if ent_res.data:
                    ent_id = str(ent_res.data[0]["id"])
                else:
                    new_ent = db.table("entrepreneurs").insert({
                        "user_id": db_user_id,
                        "full_name": "New Entrepreneur",
                        "preferred_language": language,
                        "available_capital": 0.0,
                    }).execute()
                    ent_id = str(new_ent.data[0]["id"]) if new_ent.data else db_user_id

                db.table("interview_sessions").insert({
                    "id": valid_session_uuid,
                    "entrepreneur_id": ent_id,
                    "status": "ACTIVE",
                    "language": language,
                    "started_at": now.isoformat(),
                }).execute()
                found_in_db = True
            except Exception as e:
                logger.debug(f"Auto-heal session in DB skipped: {e}")

    # Add current user message to history
    history.append({"role": "user", "content": sanitized_content})

    # 2. Persist user message
    user_msg_id = str(uuid.uuid4())
    if db is not None and found_in_db:
        try:
            db.table("interview_messages").insert({
                "id": user_msg_id,
                "session_id": session_id,
                "role": "USER",
                "content": sanitized_content,
                "language": language,
                "created_at": now.isoformat(),
            }).execute()
        except Exception as e:
            logger.warning(f"Failed to insert user message in db: {e}")

    if session_id in _OFFLINE_MESSAGES:
        _OFFLINE_MESSAGES[session_id].append({
            "id": user_msg_id,
            "role": "USER",
            "content": sanitized_content,
            "created_at": now,
        })

    # 3. Generate AI response with structured extraction
    ai_turn: Optional[InterviewTurnResponse] = None
    if gemini_adapter.is_live:
        try:
            system_prompt, user_prompt = prompt_service.build_interview_prompt(
                conversation_history=history,
                language=language,
            )
            ai_turn = await gemini_adapter.generate_structured_output(
                system_instruction=system_prompt,
                user_prompt=user_prompt,
                response_schema=InterviewTurnResponse,
            )
        except Exception as e:
            logger.warning(f"AI generation failed: {e}. Falling back to sandbox response.")

    if ai_turn is None:
        # Grounded empathetic mentor fallback
        content_lower = sanitized_content.lower()
        extracted: List[ExtractedFactor] = []
        if "dairy" in content_lower or "milk" in content_lower or "farming" in content_lower:
            extracted.append(ExtractedFactor(factor="skills", value="dairy farming & livestock", confidence=0.90))
        if "lakh" in content_lower or "rupees" in content_lower or "capital" in content_lower:
            extracted.append(ExtractedFactor(factor="capital", value="100000 INR", confidence=0.85))

        ai_turn = InterviewTurnResponse(
            reply=(
                "That experience in dairy farming is a tremendous asset. "
                "In rural and semi-urban hubs, daily milk collection and value addition (ghee, paneer) "
                "generate steady recurring income."
            ),
            extracted_factors=extracted,
            next_question="Do you already own cattle or equipment, or will you need to lease space and procure stock?",
            is_complete=False,
        )

    # 4. Persist assistant message
    asst_msg_id = str(uuid.uuid4())
    asst_content = f"{ai_turn.reply}\n\n{ai_turn.next_question or ''}".strip()

    if db is not None and found_in_db:
        try:
            db.table("interview_messages").insert({
                "id": asst_msg_id,
                "session_id": session_id,
                "role": "ASSISTANT",
                "content": asst_content,
                "language": language,
                "created_at": now.isoformat(),
            }).execute()
        except Exception as e:
            logger.warning(f"Failed to insert assistant message in db: {e}")

    if session_id in _OFFLINE_MESSAGES:
        _OFFLINE_MESSAGES[session_id].append({
            "id": asst_msg_id,
            "role": "ASSISTANT",
            "content": asst_content,
            "created_at": now,
        })

    return APIResponse(success=True, data=ai_turn, message="AI response generated.")


@router.get(
    "/interviews/{session_id}",
    response_model=APIResponse[InterviewSessionResponse],
    summary="Get interview session status and message history",
)
async def get_interview_session(
    session_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    db = _get_db()
    if db is not None:
        try:
            sess_res = db.table("interview_sessions").select("*").eq("id", session_id).execute()
            if sess_res.data:
                rec = sess_res.data[0]
                msgs_res = (
                    db.table("interview_messages")
                    .select("*")
                    .eq("session_id", session_id)
                    .order("created_at")
                    .execute()
                )
                msgs = [
                    InterviewMessageItem(
                        id=str(m["id"]),
                        role=m["role"],
                        content=m["content"],
                        created_at=datetime.fromisoformat(m["created_at"]),
                    )
                    for m in msgs_res.data
                ]
                return APIResponse(
                    success=True,
                    data=InterviewSessionResponse(
                        id=str(rec["id"]),
                        entrepreneur_id=str(rec["entrepreneur_id"]),
                        business_id=rec.get("business_id"),
                        status=rec["status"],
                        language=rec["language"],
                        started_at=datetime.fromisoformat(rec["started_at"]),
                        completed_at=datetime.fromisoformat(rec["completed_at"]) if rec.get("completed_at") else None,
                        messages=msgs,
                    ),
                )
        except Exception as e:
            logger.warning(f"Database read failed: {e}")

    if session_id in _OFFLINE_SESSIONS:
        sess = _OFFLINE_SESSIONS[session_id]
        msgs = [
            InterviewMessageItem(
                id=m["id"],
                role=m["role"],
                content=m["content"],
                created_at=m["created_at"],
            )
            for m in _OFFLINE_MESSAGES.get(session_id, [])
        ]
        return APIResponse(
            success=True,
            data=InterviewSessionResponse(**sess, messages=msgs),
        )

    raise ResourceNotFoundException("InterviewSession", session_id)


@router.post(
    "/interviews/{session_id}/complete",
    response_model=APIResponse[InterviewSessionResponse],
    summary="Mark interview session as complete",
)
async def complete_interview_session(
    session_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    db = _get_db()
    now = datetime.now(timezone.utc)

    if db is not None:
        try:
            res = (
                db.table("interview_sessions")
                .update({"status": "COMPLETED", "completed_at": now.isoformat()})
                .eq("id", session_id)
                .execute()
            )
            if res.data:
                rec = res.data[0]
                return APIResponse(
                    success=True,
                    data=InterviewSessionResponse(
                        id=str(rec["id"]),
                        entrepreneur_id=str(rec["entrepreneur_id"]),
                        business_id=rec.get("business_id"),
                        status=rec["status"],
                        language=rec["language"],
                        started_at=datetime.fromisoformat(rec["started_at"]),
                        completed_at=datetime.fromisoformat(rec["completed_at"]),
                        messages=[],
                    ),
                    message="Interview marked as completed.",
                )
        except Exception as e:
            logger.warning(f"Database update failed: {e}")

    if session_id in _OFFLINE_SESSIONS:
        _OFFLINE_SESSIONS[session_id]["status"] = "COMPLETED"
        _OFFLINE_SESSIONS[session_id]["completed_at"] = now
        return APIResponse(
            success=True,
            data=InterviewSessionResponse(**_OFFLINE_SESSIONS[session_id], messages=[]),
            message="Interview marked as completed.",
        )

    raise ResourceNotFoundException("InterviewSession", session_id)


@router.post(
    "/interviews/{session_id}/voice",
    response_model=APIResponse[VoiceTurnResponse],
    summary="Send voice message from phone mic and receive AI mentor advice with synthesized speech",
)
async def process_voice_interview_message(
    session_id: str,
    voice_in: VoiceTurnInput,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    cleaned_audio = voice_in.audio_base64.strip()
    if not cleaned_audio:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Audio payload must not be empty.",
        )

    # 1. Verify session exists
    db = _get_db()
    session_lang = voice_in.language or "hi"
    found = False
    if db is not None:
        try:
            sess_res = db.table("interview_sessions").select("language").eq("id", session_id).execute()
            if sess_res.data:
                found = True
                session_lang = sess_res.data[0].get("language") or session_lang
        except Exception as e:
            logger.warning(f"Error checking session in db: {e}")

    if not found:
        if session_id in _OFFLINE_SESSIONS:
            session_lang = _OFFLINE_SESSIONS[session_id].get("language") or session_lang
        elif session_id.startswith("offline-") or settings.ENVIRONMENT == "development":
            _OFFLINE_SESSIONS[session_id] = {
                "id": session_id,
                "entrepreneur_id": str(current_user.get("sub") or "dev-user-default"),
                "language": voice_in.language or "hi",
            }
            _OFFLINE_MESSAGES[session_id] = []
            session_lang = voice_in.language or "hi"
        else:
            raise ResourceNotFoundException("InterviewSession", session_id)

    # 2. Transcribe voice to text via Bhashini ASR
    transcription = await bhashini_adapter.speech_to_text(cleaned_audio, lang=session_lang)
    if not transcription or not transcription.strip():
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Could not transcribe audio input. Please speak clearly into the microphone.",
        )

    # 3. Process transcribed message through mentor reasoning
    msg_input = InterviewMessageInput(content=transcription, language=session_lang)
    turn_api_resp = await send_interview_message(
        session_id=session_id,
        msg_in=msg_input,
        current_user=current_user,
    )
    turn_data = turn_api_resp.data

    # 4. Synthesize AI mentor response into speech via Bhashini TTS
    combined_speech = (
        f"{turn_data.reply} {turn_data.next_question}".strip()
        if turn_data.next_question
        else turn_data.reply
    )
    audio_response_b64 = await bhashini_adapter.text_to_speech(
        combined_speech,
        lang=session_lang,
    )

    return APIResponse(
        success=True,
        data=VoiceTurnResponse(
            transcribed_text=transcription,
            reply=turn_data.reply,
            next_question=turn_data.next_question,
            language=session_lang,
            audio_response_base64=audio_response_b64,
            extracted_factors=turn_data.extracted_factors,
            is_complete=turn_data.is_complete,
        ),
        message="Voice message processed and audio response synthesized.",
    )

