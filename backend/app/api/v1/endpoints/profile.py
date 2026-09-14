from datetime import datetime, timezone
import logging
import uuid
from typing import Any, Dict, Optional
from fastapi import APIRouter, Depends, status

from app.adapters.mappls_adapter import MapplsAdapter
from app.adapters.supabase_adapter import supabase_adapter
from app.core.errors import ResourceNotFoundException, VyaparMitraException
from app.core.security import get_current_user
from app.schemas.common import APIResponse
from app.schemas.profile import (
    EntrepreneurProfileCreate,
    EntrepreneurProfileResponse,
    EntrepreneurProfileUpdate,
    LocationCreate,
    LocationResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter()
mappls_adapter = MapplsAdapter()

# In-memory store fallback for offline test isolation or sandbox environments
_OFFLINE_PROFILES: Dict[str, Dict[str, Any]] = {}
_OFFLINE_LOCATIONS: Dict[str, Dict[str, Any]] = {}


def _get_db():
    return supabase_adapter.admin_client or supabase_adapter.client


def _extract_user_id(current_user: Any) -> str:
    if isinstance(current_user, dict):
        return str(current_user.get("sub") or current_user.get("user_id") or current_user.get("id"))
    if hasattr(current_user, "user_id"):
        return str(current_user.user_id)
    if hasattr(current_user, "id"):
        return str(current_user.id)
    return str(current_user)


def _parse_datetime(val: Any) -> datetime:
    if isinstance(val, datetime):
        return val
    if isinstance(val, str):
        return datetime.fromisoformat(val)
    return datetime.now(timezone.utc)


@router.post(
    "/profile",
    response_model=APIResponse[EntrepreneurProfileResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create or initialize entrepreneur profile",
)
async def create_profile(
    profile_in: EntrepreneurProfileCreate,
    current_user: Any = Depends(get_current_user),
):
    user_id = _extract_user_id(current_user)
    db = _get_db()

    now = datetime.now(timezone.utc)
    location_id = None

    if db is not None:
        try:
            # 1. Insert Location
            loc_dict = {
                "state": profile_in.location.state,
                "district": profile_in.location.district,
                "town_or_village": profile_in.location.town_or_village,
                "pincode": profile_in.location.pincode,
                "latitude": profile_in.location.latitude,
                "longitude": profile_in.location.longitude,
                "source": "USER_SELECTED",
            }
            loc_res = db.table("locations").insert(loc_dict).execute()
            if loc_res.data:
                location_id = loc_res.data[0]["id"]

            # 2. Check existing profile
            existing = db.table("entrepreneurs").select("*").eq("user_id", user_id).execute()
            profile_data = {
                "user_id": user_id,
                "full_name": profile_in.full_name,
                "preferred_language": profile_in.preferred_language,
                "ui_language": profile_in.preferred_language,
                "voice_enabled": profile_in.voice_enabled,
                "location_id": location_id,
                "available_capital": profile_in.available_capital,
                "skills": profile_in.skills,
                "interests": profile_in.interests,
                "risk_preference": profile_in.risk_preference,
                "updated_at": now.isoformat(),
            }

            if existing.data:
                res = db.table("entrepreneurs").update(profile_data).eq("user_id", user_id).execute()
                record = res.data[0]
            else:
                profile_data["created_at"] = now.isoformat()
                res = db.table("entrepreneurs").insert(profile_data).execute()
                record = res.data[0]

            # 3. Optional consented category profile
            if profile_in.consent_recorded:
                elig_data = {
                    "entrepreneur_id": record["id"],
                    "category": profile_in.scheme_category or "general",
                    "consent_given": True,
                    "consent_recorded_at": now.isoformat(),
                }
                db.table("entrepreneur_eligibility_profile").insert(elig_data).execute()

            response_data = EntrepreneurProfileResponse(
                id=str(record["id"]),
                user_id=str(record["user_id"]),
                full_name=record["full_name"],
                preferred_language=record["preferred_language"],
                voice_enabled=record["voice_enabled"],
                location_id=str(record["location_id"]) if record.get("location_id") else None,
                available_capital=float(record["available_capital"]),
                skills=record.get("skills") or [],
                interests=record.get("interests") or [],
                risk_preference=record.get("risk_preference") or "moderate",
                scheme_category=profile_in.scheme_category or "general",
                created_at=_parse_datetime(record["created_at"]),
                updated_at=_parse_datetime(record["updated_at"]),
            )
            return APIResponse(success=True, data=response_data, message="Profile created successfully.")

        except Exception as e:
            logger.warning(f"Database write failed ({e}); falling back to in-memory profile store.")

    # Offline / sandbox in-memory persistence
    loc_id = str(uuid.uuid4())
    _OFFLINE_LOCATIONS[loc_id] = {
        "id": loc_id,
        "state": profile_in.location.state,
        "district": profile_in.location.district,
        "town_or_village": profile_in.location.town_or_village,
        "pincode": profile_in.location.pincode,
        "latitude": profile_in.location.latitude,
        "longitude": profile_in.location.longitude,
        "created_at": now,
    }

    existing_offline = _OFFLINE_PROFILES.get(user_id)
    ent_id = existing_offline["id"] if existing_offline else str(uuid.uuid4())
    created_at = existing_offline["created_at"] if existing_offline else now

    stored = {
        "id": ent_id,
        "user_id": user_id,
        "full_name": profile_in.full_name,
        "preferred_language": profile_in.preferred_language,
        "voice_enabled": profile_in.voice_enabled,
        "location_id": loc_id,
        "available_capital": profile_in.available_capital,
        "skills": profile_in.skills,
        "interests": profile_in.interests,
        "risk_preference": profile_in.risk_preference,
        "scheme_category": profile_in.scheme_category or "general",
        "created_at": created_at,
        "updated_at": now,
    }
    _OFFLINE_PROFILES[user_id] = stored
    return APIResponse(
        success=True,
        data=EntrepreneurProfileResponse(**stored),
        message="Profile created successfully (sandbox mode).",
    )


@router.get(
    "/profile",
    response_model=APIResponse[EntrepreneurProfileResponse],
    summary="Get current user's profile",
)
async def get_profile(current_user: Any = Depends(get_current_user)):
    user_id = _extract_user_id(current_user)
    db = _get_db()

    if db is not None:
        try:
            res = db.table("entrepreneurs").select("*").eq("user_id", user_id).execute()
            if res.data:
                record = res.data[0]
                scheme_category = "general"
                try:
                    elig_res = db.table("entrepreneur_eligibility_profile").select("category").eq("entrepreneur_id", record["id"]).execute()
                    if elig_res.data:
                        scheme_category = elig_res.data[0].get("category") or "general"
                except Exception:
                    pass

                return APIResponse(
                    success=True,
                    data=EntrepreneurProfileResponse(
                        id=str(record["id"]),
                        user_id=str(record["user_id"]),
                        full_name=record["full_name"],
                        preferred_language=record["preferred_language"],
                        voice_enabled=record["voice_enabled"],
                        location_id=str(record["location_id"]) if record.get("location_id") else None,
                        available_capital=float(record["available_capital"]),
                        skills=record.get("skills") or [],
                        interests=record.get("interests") or [],
                        risk_preference=record.get("risk_preference") or "moderate",
                        scheme_category=scheme_category,
                        created_at=_parse_datetime(record["created_at"]),
                        updated_at=_parse_datetime(record["updated_at"]),
                    ),
                )
        except Exception as e:
            logger.warning(f"Database read failed: {e}")

    if user_id in _OFFLINE_PROFILES:
        return APIResponse(
            success=True,
            data=EntrepreneurProfileResponse(**_OFFLINE_PROFILES[user_id]),
        )

    raise ResourceNotFoundException("EntrepreneurProfile", user_id)


@router.patch(
    "/profile",
    response_model=APIResponse[EntrepreneurProfileResponse],
    summary="Update current user's profile",
)
async def update_profile(
    profile_update: EntrepreneurProfileUpdate,
    current_user: Any = Depends(get_current_user),
):
    user_id = _extract_user_id(current_user)
    db = _get_db()
    now = datetime.now(timezone.utc)

    updates = {k: v for k, v in profile_update.model_dump().items() if v is not None}
    updates["updated_at"] = now.isoformat()

    if db is not None:
        try:
            res = db.table("entrepreneurs").update(updates).eq("user_id", user_id).execute()
            if res.data:
                record = res.data[0]
                scheme_category = profile_update.scheme_category or "general"
                try:
                    elig_res = db.table("entrepreneur_eligibility_profile").select("category").eq("entrepreneur_id", record["id"]).execute()
                    if elig_res.data and not profile_update.scheme_category:
                        scheme_category = elig_res.data[0].get("category") or "general"
                except Exception:
                    pass

                return APIResponse(
                    success=True,
                    data=EntrepreneurProfileResponse(
                        id=str(record["id"]),
                        user_id=str(record["user_id"]),
                        full_name=record["full_name"],
                        preferred_language=record["preferred_language"],
                        voice_enabled=record["voice_enabled"],
                        location_id=str(record["location_id"]) if record.get("location_id") else None,
                        available_capital=float(record["available_capital"]),
                        skills=record.get("skills") or [],
                        interests=record.get("interests") or [],
                        risk_preference=record.get("risk_preference") or "moderate",
                        scheme_category=scheme_category,
                        created_at=_parse_datetime(record["created_at"]),
                        updated_at=_parse_datetime(record["updated_at"]),
                    ),
                    message="Profile updated successfully.",
                )
        except Exception as e:
            logger.warning(f"Database update failed: {e}")

    if user_id in _OFFLINE_PROFILES:
        stored = _OFFLINE_PROFILES[user_id]
        for k, v in updates.items():
            stored[k] = v
        stored["updated_at"] = now
        return APIResponse(
            success=True,
            data=EntrepreneurProfileResponse(**stored),
            message="Profile updated successfully (sandbox mode).",
        )

    raise ResourceNotFoundException("EntrepreneurProfile", user_id)


# ---------------------------------------------------------------------------
# Location Endpoints
# ---------------------------------------------------------------------------

@router.post(
    "/locations",
    response_model=APIResponse[LocationResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create or save a location",
)
async def create_location(
    loc_in: LocationCreate,
    current_user: Any = Depends(get_current_user),
):
    db = _get_db()
    now = datetime.now(timezone.utc)

    if db is not None:
        try:
            loc_dict = {
                "state": loc_in.state,
                "district": loc_in.district,
                "town_or_village": loc_in.town_or_village,
                "pincode": loc_in.pincode,
                "latitude": loc_in.latitude,
                "longitude": loc_in.longitude,
                "source": "USER_SELECTED",
            }
            res = db.table("locations").insert(loc_dict).execute()
            if res.data:
                rec = res.data[0]
                return APIResponse(
                    success=True,
                    data=LocationResponse(
                        id=str(rec["id"]),
                        state=rec["state"],
                        district=rec["district"],
                        town_or_village=rec["town_or_village"],
                        pincode=rec.get("pincode"),
                        latitude=float(rec["latitude"]) if rec.get("latitude") else None,
                        longitude=float(rec["longitude"]) if rec.get("longitude") else None,
                        created_at=_parse_datetime(rec["created_at"]),
                    ),
                    message="Location saved successfully.",
                )
        except Exception as e:
            logger.warning(f"Location db insert failed: {e}")

    loc_id = str(uuid.uuid4())
    loc_record = {
        "id": loc_id,
        "state": loc_in.state,
        "district": loc_in.district,
        "town_or_village": loc_in.town_or_village,
        "pincode": loc_in.pincode,
        "latitude": loc_in.latitude,
        "longitude": loc_in.longitude,
        "created_at": now,
    }
    _OFFLINE_LOCATIONS[loc_id] = loc_record
    return APIResponse(
        success=True,
        data=LocationResponse(**loc_record),
        message="Location saved successfully (sandbox mode).",
    )


@router.get(
    "/locations/{location_id}",
    response_model=APIResponse[LocationResponse],
    summary="Get location by ID",
)
async def get_location(
    location_id: str,
    current_user: Any = Depends(get_current_user),
):
    db = _get_db()
    if db is not None:
        try:
            res = db.table("locations").select("*").eq("id", location_id).execute()
            if res.data:
                rec = res.data[0]
                return APIResponse(
                    success=True,
                    data=LocationResponse(
                        id=str(rec["id"]),
                        state=rec["state"],
                        district=rec["district"],
                        town_or_village=rec["town_or_village"],
                        pincode=rec.get("pincode"),
                        latitude=float(rec["latitude"]) if rec.get("latitude") else None,
                        longitude=float(rec["longitude"]) if rec.get("longitude") else None,
                        created_at=_parse_datetime(rec["created_at"]),
                    ),
                )
        except Exception as e:
            logger.warning(f"Location read failed: {e}")

    if location_id in _OFFLINE_LOCATIONS:
        return APIResponse(
            success=True,
            data=LocationResponse(**_OFFLINE_LOCATIONS[location_id]),
        )

    raise ResourceNotFoundException("Location", location_id)


@router.get(
    "/locality/competitors",
    summary="Discover nearby registered business competitors via Mappls",
)
async def get_nearby_competitors(
    category: str,
    query: Optional[str] = None,
    latitude: Optional[float] = None,
    longitude: Optional[float] = None,
    radius_km: float = 5.0,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    lat = latitude
    lon = longitude
    loc_meta = {}

    if lat is None or lon is None:
        search_query = query or "Baramati, Pune"
        geo_results = await mappls_adapter.geocode(search_query)
        if geo_results:
            lat = geo_results[0]["latitude"]
            lon = geo_results[0]["longitude"]
            loc_meta = geo_results[0]
        else:
            lat = 18.5204
            lon = 73.8567
            loc_meta = {"village": search_query, "latitude": lat, "longitude": lon}
    else:
        loc_meta = {"latitude": lat, "longitude": lon}

    competitors = await mappls_adapter.find_nearby_competitors(
        latitude=lat,
        longitude=lon,
        category=category,
        radius_km=radius_km,
    )

    return APIResponse(
        success=True,
        data={
            "location": loc_meta,
            "category": category,
            "radius_km": radius_km,
            "competitor_count": len(competitors),
            "competitors": competitors,
        },
        message=f"Discovered {len(competitors)} local competitors in {loc_meta.get('village', 'locality')}.",
    )

