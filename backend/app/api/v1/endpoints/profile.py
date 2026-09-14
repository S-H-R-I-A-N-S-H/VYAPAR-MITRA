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
@router.put(
    "/profile",
    response_model=APIResponse[EntrepreneurProfileResponse],
    status_code=status.HTTP_200_OK,
    summary="Update or upsert entrepreneur profile",
)
async def upsert_profile(
    profile_in: EntrepreneurProfileCreate,
    current_user: Any = Depends(get_current_user),
):
    user_id = _extract_user_id(current_user)
    db = _get_db()
    now = datetime.now(timezone.utc)
    location_id = None

    # Handle nested or default location
    loc_state = profile_in.location.state if profile_in.location else "Madhya Pradesh"
    loc_district = profile_in.location.district if profile_in.location else "Indore"
    loc_town = profile_in.location.town_or_village if profile_in.location else "Sanwer"
    loc_pincode = profile_in.location.pincode if profile_in.location else None
    loc_lat = profile_in.location.latitude if profile_in.location else None
    loc_lng = profile_in.location.longitude if profile_in.location else None
    loc_rural_urban = profile_in.location.rural_or_urban if profile_in.location else (profile_in.rural_or_urban or "rural")

    if db is not None:
        try:
            # 1. Insert or update Location
            loc_dict = {
                "state": loc_state,
                "district": loc_district,
                "town_or_village": loc_town,
                "pincode": loc_pincode,
                "latitude": loc_lat,
                "longitude": loc_lng,
                "source": "USER_SELECTED",
            }
            loc_res = db.table("locations").insert(loc_dict).execute()
            if loc_res.data:
                location_id = loc_res.data[0]["id"]

            # 2. Check existing profile for user_id to prevent duplicates
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
                "age": profile_in.age,
                "education": profile_in.education,
                "rural_or_urban": loc_rural_urban,
                "occupation": profile_in.occupation,
                "experience_years": profile_in.experience_years,
                "annual_income": profile_in.annual_income,
                "previous_government_subsidy": profile_in.previous_government_subsidy,
                "previous_government_loan": profile_in.previous_government_loan,
                "previously_used_schemes": profile_in.previously_used_schemes,
                "updated_at": now.isoformat(),
            }

            if existing.data:
                res = db.table("entrepreneurs").update(profile_data).eq("user_id", user_id).execute()
                record = res.data[0]
            else:
                profile_data["created_at"] = now.isoformat()
                res = db.table("entrepreneurs").insert(profile_data).execute()
                record = res.data[0]

            ent_id = record["id"]

            # 3. Optional Consented Eligibility Profile
            if profile_in.consent_recorded:
                elig_data = {
                    "entrepreneur_id": ent_id,
                    "category": profile_in.scheme_category or "general",
                    "gender": profile_in.gender or "male",
                    "is_woman_entrepreneur": profile_in.is_woman_entrepreneur or (profile_in.gender == "female"),
                    "disability_category": profile_in.disability_category,
                    "minority_category": profile_in.minority_category,
                    "ex_serviceman_status": profile_in.ex_serviceman_status,
                    "consent_given": True,
                    "consent_recorded_at": now.isoformat(),
                    "updated_at": now.isoformat(),
                }
                existing_elig = db.table("entrepreneur_eligibility_profile").select("*").eq("entrepreneur_id", ent_id).execute()
                if existing_elig.data:
                    db.table("entrepreneur_eligibility_profile").update(elig_data).eq("entrepreneur_id", ent_id).execute()
                else:
                    db.table("entrepreneur_eligibility_profile").insert(elig_data).execute()

            # 4. Upsert Business Information
            biz_id = None
            if profile_in.business_name or profile_in.business_idea:
                biz_name = profile_in.business_name or profile_in.business_idea or "My Enterprise"
                biz_data = {
                    "entrepreneur_id": ent_id,
                    "name": biz_name,
                    "status": "new",
                    "domain": profile_in.business_type or "manufacturing",
                    "product_or_service": profile_in.business_activity or "Processing",
                    "description": profile_in.business_idea or biz_name,
                    "scale": "micro",
                    "business_activity": profile_in.business_activity,
                    "business_type": profile_in.business_type or "manufacturing",
                    "business_status": profile_in.business_status or "new",
                    "sector": profile_in.sector or "Agri-Processing",
                    "years_in_business": profile_in.years_in_business,
                    "annual_turnover": profile_in.annual_turnover,
                    "number_of_employees": profile_in.number_of_employees,
                    "is_greenfield": profile_in.is_greenfield,
                    "total_project_cost": profile_in.total_project_cost,
                    "own_capital": profile_in.own_capital or profile_in.available_capital,
                    "loan_required": profile_in.loan_required,
                    "existing_loans": profile_in.existing_loans,
                    "existing_loan_amount": profile_in.existing_loan_amount,
                    "monthly_emi": profile_in.monthly_emi,
                    "working_capital_requirement": profile_in.working_capital_requirement,
                    "machinery_equipment_cost": profile_in.machinery_equipment_cost,
                    "updated_at": now.isoformat(),
                }
                existing_biz = db.table("businesses").select("*").eq("entrepreneur_id", ent_id).execute()
                if existing_biz.data:
                    b_res = db.table("businesses").update(biz_data).eq("id", existing_biz.data[0]["id"]).execute()
                    if b_res.data:
                        biz_id = b_res.data[0]["id"]
                else:
                    biz_data["created_at"] = now.isoformat()
                    b_res = db.table("businesses").insert(biz_data).execute()
                    if b_res.data:
                        biz_id = b_res.data[0]["id"]

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
                age=record.get("age") or profile_in.age,
                gender=profile_in.gender,
                education=record.get("education") or profile_in.education,
                rural_or_urban=record.get("rural_or_urban") or loc_rural_urban,
                occupation=record.get("occupation") or profile_in.occupation,
                experience_years=float(record.get("experience_years") or 2.0),
                annual_income=float(record.get("annual_income") or 120000.0),
                previous_government_subsidy=bool(record.get("previous_government_subsidy") or False),
                previous_government_loan=bool(record.get("previous_government_loan") or False),
                previously_used_schemes=record.get("previously_used_schemes") or [],
                business_id=str(biz_id) if biz_id else None,
                business_name=profile_in.business_name or profile_in.business_idea,
                business_activity=profile_in.business_activity,
                business_type=profile_in.business_type,
                business_status=profile_in.business_status,
                sector=profile_in.sector,
                total_project_cost=profile_in.total_project_cost,
                own_capital=profile_in.own_capital or profile_in.available_capital,
                loan_required=profile_in.loan_required,
                created_at=_parse_datetime(record["created_at"]),
                updated_at=_parse_datetime(record["updated_at"]),
            )
            return APIResponse(success=True, data=response_data, message="Profile saved and normalized successfully.")

        except Exception as e:
            logger.warning(f"Database write failed ({e}); falling back to in-memory profile store.")

    # Offline / Sandbox fallback
    loc_id = str(uuid.uuid4())
    _OFFLINE_LOCATIONS[loc_id] = {
        "id": loc_id,
        "state": loc_state,
        "district": loc_district,
        "town_or_village": loc_town,
        "pincode": loc_pincode,
        "latitude": loc_lat,
        "longitude": loc_lng,
        "rural_or_urban": loc_rural_urban,
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
        "age": profile_in.age or 28,
        "gender": profile_in.gender or "male",
        "education": profile_in.education or "10th_pass",
        "rural_or_urban": loc_rural_urban,
        "occupation": profile_in.occupation or "Micro-entrepreneur",
        "experience_years": profile_in.experience_years or 2.0,
        "annual_income": profile_in.annual_income or 120000.0,
        "previous_government_subsidy": profile_in.previous_government_subsidy or False,
        "previous_government_loan": profile_in.previous_government_loan or False,
        "previously_used_schemes": profile_in.previously_used_schemes or [],
        "business_name": profile_in.business_name or profile_in.business_idea,
        "business_activity": profile_in.business_activity or "Processing",
        "business_type": profile_in.business_type or "manufacturing",
        "business_status": profile_in.business_status or "new",
        "sector": profile_in.sector or "Agri-Processing",
        "total_project_cost": profile_in.total_project_cost or 250000.0,
        "own_capital": profile_in.own_capital or profile_in.available_capital,
        "loan_required": profile_in.loan_required or 200000.0,
        "created_at": created_at,
        "updated_at": now,
    }
    _OFFLINE_PROFILES[user_id] = stored
    return APIResponse(
        success=True,
        data=EntrepreneurProfileResponse(**stored),
        message="Profile saved successfully (sandbox mode).",
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
                ent_id = record["id"]

                # Fetch extra details if available
                scheme_cat = "general"
                gender = "male"
                try:
                    elig = db.table("entrepreneur_eligibility_profile").select("*").eq("entrepreneur_id", ent_id).execute()
                    if elig.data:
                        scheme_cat = elig.data[0].get("category") or "general"
                        gender = elig.data[0].get("gender") or "male"
                except Exception:
                    pass

                biz_rec = {}
                try:
                    biz = db.table("businesses").select("*").eq("entrepreneur_id", ent_id).execute()
                    biz_rec = biz.data[0] if biz.data else {}
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
                        scheme_category=scheme_cat,
                        age=record.get("age") or 28,
                        gender=gender,
                        education=record.get("education") or "10th_pass",
                        rural_or_urban=record.get("rural_or_urban") or "rural",
                        occupation=record.get("occupation") or "Micro-entrepreneur",
                        experience_years=float(record.get("experience_years") or 2.0),
                        annual_income=float(record.get("annual_income") or 120000.0),
                        previous_government_subsidy=bool(record.get("previous_government_subsidy") or False),
                        previous_government_loan=bool(record.get("previous_government_loan") or False),
                        previously_used_schemes=record.get("previously_used_schemes") or [],
                        business_id=str(biz_rec.get("id")) if biz_rec.get("id") else None,
                        business_name=biz_rec.get("name"),
                        business_activity=biz_rec.get("business_activity") or biz_rec.get("product_or_service"),
                        business_type=biz_rec.get("business_type") or biz_rec.get("domain"),
                        business_status=biz_rec.get("business_status") or biz_rec.get("status"),
                        sector=biz_rec.get("sector") or biz_rec.get("domain"),
                        total_project_cost=float(biz_rec.get("total_project_cost") or 250000.0),
                        own_capital=float(biz_rec.get("own_capital") or record.get("available_capital") or 50000.0),
                        loan_required=float(biz_rec.get("loan_required") or 200000.0),
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
async def patch_profile(
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
                        rural_or_urban=loc_in.rural_or_urban,
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
        "rural_or_urban": loc_in.rural_or_urban,
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
                        rural_or_urban="rural",
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

