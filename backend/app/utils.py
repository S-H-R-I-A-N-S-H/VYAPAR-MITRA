"""
app/utils.py
Shared utility helpers used across multiple endpoint modules.
Eliminates the duplicated _extract_user_id() and _parse_datetime() functions
that previously existed in profile.py, businesses.py, opportunities.py, interview.py.
"""
import logging
from datetime import datetime, timezone
from typing import Any, Dict, Optional

from app.core.config import settings
from app.core.errors import ServiceUnavailableException

logger = logging.getLogger(__name__)


def extract_user_id(current_user: Any) -> str:
    """
    Safely extracts the authenticated user's UUID string from the
    AuthenticatedUser model or a raw dict (legacy compatibility).
    """
    if hasattr(current_user, "user_id"):
        return str(current_user.user_id)
    if isinstance(current_user, dict):
        uid = current_user.get("sub") or current_user.get("user_id") or current_user.get("id")
        if uid:
            return str(uid)
    raise ValueError(f"Cannot extract user_id from current_user of type {type(current_user)}")


def parse_db_datetime(value: Any) -> datetime:
    """
    Parses a datetime value returned from Supabase (ISO string or datetime object).
    Always returns a timezone-aware UTC datetime.
    """
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    if isinstance(value, str):
        try:
            dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
            return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
        except ValueError:
            pass
    return datetime.now(timezone.utc)


def is_production() -> bool:
    """Returns True if the app is running in production mode."""
    return settings.ENVIRONMENT == "production"


def require_db(db: Any, operation: str = "database operation") -> Any:
    """
    Raises ServiceUnavailableException if the DB client is None in production.
    In development mode, returns None and lets the caller fall back to sandbox.
    This prevents silent data loss in production.

    Usage:
        db = _get_db()
        if db is None:
            require_db(db, "create business")   # raises in prod, passes in dev
            # Offline fallback code here...
    """
    if db is None and is_production():
        logger.error(f"Database unavailable for {operation} in production mode.")
        raise ServiceUnavailableException(
            f"Database is temporarily unavailable. Please try again shortly."
        )
    return db


def should_use_offline_fallback(db: Any) -> bool:
    """
    Returns True ONLY if:
    1. The DB client is None (unavailable), AND
    2. We are NOT in production (sandbox mode is allowed)
    In production, DB unavailability should propagate as an error, not silently use in-memory storage.
    """
    if db is not None:
        return False
    if is_production():
        return False  # Will have already raised via require_db()
    return True


def get_user_entrepreneur_ids(db: Any, user_id: str) -> set:
    """
    Resolves all valid entrepreneur ID representations for a given auth user_id:
    - The raw user_id string itself
    - Any offline profile ID associated with user_id
    - The database entrepreneur.id UUID associated with user_id
    """
    import uuid
    ids = {str(user_id)}
    try:
        from app.api.v1.endpoints.profile import _OFFLINE_PROFILES
        if user_id in _OFFLINE_PROFILES:
            prof_id = _OFFLINE_PROFILES[user_id].get("id")
            if prof_id:
                ids.add(str(prof_id))
    except Exception:
        pass

    if db is not None:
        try:
            try:
                db_uid = str(uuid.UUID(str(user_id)))
            except ValueError:
                db_uid = str(uuid.uuid5(uuid.NAMESPACE_DNS, str(user_id)))
            res = db.table("entrepreneurs").select("id").eq("user_id", db_uid).execute()
            if res.data:
                for row in res.data:
                    ids.add(str(row["id"]))
        except Exception as e:
            logger.warning(f"Could not resolve entrepreneur_id in DB: {e}")
    return ids


def verify_session_ownership(db: Any, session_id: str, current_user: Any, session_record: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """
    Verifies that the session exists and belongs to the authenticated user.
    Raises ResourceNotFoundException if missing.
    Raises ForbiddenOperationException if owned by another user.
    """
    from app.core.errors import ForbiddenOperationException, ResourceNotFoundException
    from app.api.v1.endpoints.interview import _OFFLINE_SESSIONS

    user_id = extract_user_id(current_user)
    rec = session_record

    if rec is None and db is not None:
        try:
            res = db.table("interview_sessions").select("*").eq("id", session_id).execute()
            if res.data:
                rec = res.data[0]
        except Exception as e:
            logger.warning(f"Database error during session lookup: {e}")

    if rec is None and session_id in _OFFLINE_SESSIONS:
        rec = _OFFLINE_SESSIONS[session_id]

    if rec is None:
        raise ResourceNotFoundException("InterviewSession", session_id)

    allowed_ids = get_user_entrepreneur_ids(db, user_id)
    if str(rec.get("entrepreneur_id")) not in allowed_ids:
        raise ForbiddenOperationException("You do not have permission to access this interview session.")

    return rec


import uuid


def is_valid_uuid(val: Any) -> bool:
    """Returns True if val is a valid UUID string or UUID object."""
    try:
        uuid.UUID(str(val))
        return True
    except (ValueError, AttributeError, TypeError):
        return False


def to_deterministic_uuid(val: Any) -> str:
    """Converts any string to a deterministic, valid UUID string."""
    try:
        return str(uuid.UUID(str(val)))
    except (ValueError, AttributeError, TypeError):
        return str(uuid.uuid5(uuid.NAMESPACE_DNS, str(val)))


def verify_session_ownership(db: Any, session_id: str, current_user: Any, session_record: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """
    Verifies that the session exists and belongs to the authenticated user.
    Raises ResourceNotFoundException if missing.
    Raises ForbiddenOperationException if owned by another user.
    """
    from app.core.errors import ForbiddenOperationException, ResourceNotFoundException
    from app.api.v1.endpoints.interview import _OFFLINE_SESSIONS

    user_id = extract_user_id(current_user)
    rec = session_record

    if rec is None and db is not None:
        if is_valid_uuid(session_id):
            try:
                res = db.table("interview_sessions").select("*").eq("id", session_id).execute()
                if res.data:
                    rec = res.data[0]
            except Exception as e:
                logger.warning(f"Database error during session lookup: {e}")

    if rec is None and session_id in _OFFLINE_SESSIONS:
        rec = _OFFLINE_SESSIONS[session_id]

    if rec is None:
        raise ResourceNotFoundException("InterviewSession", session_id)

    allowed_ids = get_user_entrepreneur_ids(db, user_id)
    if not allowed_ids:
        allowed_ids.add(to_deterministic_uuid(user_id))
    if str(rec.get("entrepreneur_id")) not in allowed_ids:
        raise ForbiddenOperationException("You do not have permission to access this interview session.")

    return rec


def verify_business_ownership(db: Any, business_id: str, current_user: Any, business_record: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """
    Verifies that the business exists and belongs to the authenticated user.
    Raises ResourceNotFoundException if missing.
    Raises ForbiddenOperationException if owned by another user.
    """
    from app.core.errors import ForbiddenOperationException, ResourceNotFoundException
    from app.api.v1.endpoints.opportunities import _OFFLINE_BUSINESSES

    user_id = extract_user_id(current_user)
    rec = business_record

    if rec is None and db is not None:
        if is_valid_uuid(business_id):
            try:
                res = db.table("businesses").select("*").eq("id", business_id).execute()
                if res.data:
                    rec = res.data[0]
            except Exception as e:
                logger.warning(f"Database error during business lookup: {e}")

    if rec is None and business_id in _OFFLINE_BUSINESSES:
        rec = _OFFLINE_BUSINESSES[business_id]

    if rec is None:
        raise ResourceNotFoundException("Business", business_id)

    allowed_ids = get_user_entrepreneur_ids(db, user_id)
    if not allowed_ids:
        allowed_ids.add(to_deterministic_uuid(user_id))
    if str(rec.get("entrepreneur_id")) not in allowed_ids:
        raise ForbiddenOperationException("You do not have permission to access this business.")

    return rec


def verify_research_project_ownership(db: Any, project_id: str, current_user: Any, project_record: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """
    Verifies that the research project exists and that its business belongs to the authenticated user.
    Raises ResourceNotFoundException if missing.
    Raises ForbiddenOperationException if owned by another user.
    """
    from app.core.errors import ResourceNotFoundException
    from app.api.v1.endpoints.research import _OFFLINE_PROJECTS

    rec = project_record
    if rec is None and db is not None:
        if is_valid_uuid(project_id):
            try:
                res = db.table("research_projects").select("*").eq("id", project_id).execute()
                if res.data:
                    rec = res.data[0]
            except Exception as e:
                logger.warning(f"Database error during research project lookup: {e}")

    if rec is None and project_id in _OFFLINE_PROJECTS:
        rec = _OFFLINE_PROJECTS[project_id]

    if rec is None:
        raise ResourceNotFoundException("ResearchProject", project_id)

    verify_business_ownership(db, str(rec["business_id"]), current_user)
    return rec


def verify_financial_scenario_ownership(db: Any, scenario_id: str, current_user: Any, scenario_record: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """
    Verifies that the financial scenario exists and that its business belongs to the authenticated user.
    Raises ResourceNotFoundException if missing.
    Raises ForbiddenOperationException if owned by another user.
    """
    from app.core.errors import ResourceNotFoundException
    from app.api.v1.endpoints.finance import _OFFLINE_SCENARIOS

    rec = scenario_record
    if rec is None and db is not None:
        if is_valid_uuid(scenario_id):
            try:
                res = db.table("financial_scenarios").select("*").eq("id", scenario_id).execute()
                if res.data:
                    rec = res.data[0]
            except Exception as e:
                logger.warning(f"Database error during financial scenario lookup: {e}")

    if rec is None and scenario_id in _OFFLINE_SCENARIOS:
        rec = _OFFLINE_SCENARIOS[scenario_id]

    if rec is None:
        raise ResourceNotFoundException("FinancialScenario", scenario_id)

    verify_business_ownership(db, str(rec["business_id"]), current_user)
    return rec


def verify_survey_ownership(db: Any, survey_id: str, current_user: Any, survey_record: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """
    Verifies that the survey exists and that its research project / business belongs to the authenticated user.
    Raises ResourceNotFoundException if missing.
    Raises ForbiddenOperationException if owned by another user.
    """
    from app.core.errors import ResourceNotFoundException
    from app.api.v1.endpoints.surveys import _OFFLINE_SURVEYS

    rec = survey_record
    if rec is None and db is not None:
        if is_valid_uuid(survey_id):
            try:
                res = db.table("surveys").select("*").eq("id", survey_id).execute()
                if res.data:
                    rec = res.data[0]
            except Exception as e:
                logger.warning(f"Database error during survey lookup: {e}")

    if rec is None and survey_id in _OFFLINE_SURVEYS:
        rec = _OFFLINE_SURVEYS[survey_id]

    if rec is None:
        raise ResourceNotFoundException("Survey", survey_id)

    verify_research_project_ownership(db, str(rec["research_project_id"]), current_user)
    return rec


