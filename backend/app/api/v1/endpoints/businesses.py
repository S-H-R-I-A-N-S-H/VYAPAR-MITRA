from datetime import datetime, timezone
import logging
import uuid
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, status

from app.adapters.supabase_adapter import supabase_adapter
from app.api.v1.endpoints.opportunities import _OFFLINE_BUSINESSES, _OFFLINE_VERSIONS
from app.api.v1.endpoints.profile import _OFFLINE_PROFILES
from app.core.errors import (
    ForbiddenOperationException,
    ResourceNotFoundException,
    ServiceUnavailableException,
    VyaparMitraException,
)
from app.core.security import AuthenticatedUser, get_current_user
from app.schemas.business import (
    BusinessCreate,
    BusinessResponse,
    BusinessUpdate,
    BusinessVersionCreate,
    BusinessVersionResponse,
)
from app.schemas.common import APIResponse, PaginationParams

from app.utils import (
    extract_user_id,
    is_production,
    parse_db_datetime,
    require_db,
    verify_business_ownership,
)

logger = logging.getLogger(__name__)

router = APIRouter()


def _get_db():
    return supabase_adapter.admin_client or supabase_adapter.client


_extract_user_id = extract_user_id
_parse_datetime = parse_db_datetime


@router.post(
    "/businesses",
    response_model=APIResponse[BusinessResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create a new business idea",
)
async def create_business(
    biz_in: BusinessCreate,
    current_user: Any = Depends(get_current_user),
):
    user_id = _extract_user_id(current_user)
    db = _get_db()
    now = datetime.now(timezone.utc)

    biz_id = str(uuid.uuid4())
    entrepreneur_id = user_id

    if db is not None:
        try:
            ent_res = db.table("entrepreneurs").select("id").eq("user_id", user_id).execute()
            if ent_res.data:
                entrepreneur_id = str(ent_res.data[0]["id"])
            else:
                new_ent = db.table("entrepreneurs").insert({
                    "user_id": user_id,
                    "full_name": "New Entrepreneur",
                }).execute()
                if new_ent.data:
                    entrepreneur_id = str(new_ent.data[0]["id"])

            insert_dict = {
                "id": biz_id,
                "entrepreneur_id": entrepreneur_id,
                "name": biz_in.name,
                "status": "IDEA",
                "domain": biz_in.domain,
                "product_or_service": biz_in.product_or_service,
                "business_model": biz_in.business_model,
                "description": biz_in.description,
                "target_customer": biz_in.target_customer,
                "intended_market": biz_in.intended_market,
                "scale": biz_in.scale or "micro",
                "created_at": now.isoformat(),
                "updated_at": now.isoformat(),
            }
            res = db.table("businesses").insert(insert_dict).execute()
            if res.data:
                rec = res.data[0]
                db.table("business_versions").insert({
                    "business_id": biz_id,
                    "version_number": 1,
                    "business_definition": biz_in.description or biz_in.name,
                    "assumptions": {},
                    "source": "USER",
                    "created_at": now.isoformat(),
                }).execute()

                return APIResponse(
                    success=True,
                    data=BusinessResponse(
                        id=str(rec["id"]),
                        entrepreneur_id=str(rec["entrepreneur_id"]),
                        name=rec["name"],
                        status=rec["status"],
                        domain=rec["domain"],
                        product_or_service=rec["product_or_service"],
                        business_model=rec.get("business_model"),
                        description=rec.get("description"),
                        target_customer=rec.get("target_customer"),
                        intended_market=rec.get("intended_market"),
                        scale=rec.get("scale") or "micro",
                        created_at=_parse_datetime(rec["created_at"]),
                        updated_at=_parse_datetime(rec["updated_at"]),
                    ),
                    message="Business idea created successfully.",
                )
        except Exception as e:
            logger.warning(f"Failed to create business in database: {e}")

    # Fallback to offline store
    offline_profile = _OFFLINE_PROFILES.get(user_id)
    entrepreneur_id = offline_profile["id"] if offline_profile else user_id

    biz_record = {
        "id": biz_id,
        "entrepreneur_id": entrepreneur_id,
        "name": biz_in.name,
        "status": "IDEA",
        "domain": biz_in.domain,
        "product_or_service": biz_in.product_or_service,
        "business_model": biz_in.business_model,
        "description": biz_in.description,
        "target_customer": biz_in.target_customer,
        "intended_market": biz_in.intended_market,
        "scale": biz_in.scale or "micro",
        "created_at": now,
        "updated_at": now,
    }
    _OFFLINE_BUSINESSES[biz_id] = biz_record
    _OFFLINE_VERSIONS[biz_id] = [{
        "id": str(uuid.uuid4()),
        "business_id": biz_id,
        "version_number": 1,
        "business_definition": biz_in.description or biz_in.name,
        "assumptions": {},
        "source": "USER",
        "created_at": now,
    }]

    return APIResponse(
        success=True,
        data=BusinessResponse(**biz_record),
        message="Business idea created (sandbox mode).",
    )


@router.get(
    "/businesses",
    response_model=APIResponse[List[BusinessResponse]],
    summary="List all businesses for authenticated entrepreneur",
)
async def list_businesses(
    pagination: PaginationParams = Depends(),
    current_user: AuthenticatedUser = Depends(get_current_user),
):
    user_id = _extract_user_id(current_user)
    db = _get_db()
    result_list: List[BusinessResponse] = []

    if db is not None:
        try:
            ent_res = db.table("entrepreneurs").select("id").eq("user_id", user_id).execute()
            if ent_res.data:
                entrepreneur_id = str(ent_res.data[0]["id"])
                start, end = pagination.range_offset()
                res = (
                    db.table("businesses")
                    .select("*, business_versions(*)")
                    .eq("entrepreneur_id", entrepreneur_id)
                    .order("created_at", desc=True)
                    .range(start, end)
                    .execute()
                )
                for rec in res.data:
                    result_list.append(
                        BusinessResponse(
                            id=str(rec["id"]),
                            entrepreneur_id=str(rec["entrepreneur_id"]),
                            name=rec["name"],
                            status=rec["status"],
                            domain=rec["domain"],
                            product_or_service=rec["product_or_service"],
                            business_model=rec.get("business_model"),
                            description=rec.get("description"),
                            target_customer=rec.get("target_customer"),
                            intended_market=rec.get("intended_market"),
                            scale=rec.get("scale") or "micro",
                            created_at=_parse_datetime(rec["created_at"]),
                            updated_at=_parse_datetime(rec["updated_at"]),
                        )
                    )
                return APIResponse(success=True, data=result_list)
        except Exception as e:
            logger.warning(f"Database list businesses failed: {e}")

    # Fallback to offline store
    allowed_ent_ids = {user_id}
    if user_id in _OFFLINE_PROFILES:
        allowed_ent_ids.add(str(_OFFLINE_PROFILES[user_id].get("id")))

    for b_id, rec in _OFFLINE_BUSINESSES.items():
        if rec.get("entrepreneur_id") in allowed_ent_ids:
            result_list.append(BusinessResponse(**rec))

    paginated_fallback = result_list[pagination.offset : pagination.offset + pagination.limit]
    return APIResponse(success=True, data=paginated_fallback)



@router.get(
    "/businesses/{business_id}",
    response_model=APIResponse[BusinessResponse],
    summary="Get business details by ID",
)
async def get_business(
    business_id: str,
    current_user: Any = Depends(get_current_user),
):
    db = _get_db()
    rec = verify_business_ownership(db, business_id, current_user)
    return APIResponse(
        success=True,
        data=BusinessResponse(
            id=str(rec["id"]),
            entrepreneur_id=str(rec["entrepreneur_id"]),
            name=rec["name"],
            status=rec["status"],
            domain=rec["domain"],
            product_or_service=rec["product_or_service"],
            business_model=rec.get("business_model"),
            description=rec.get("description"),
            target_customer=rec.get("target_customer"),
            intended_market=rec.get("intended_market"),
            scale=rec.get("scale") or "micro",
            created_at=_parse_datetime(rec["created_at"]),
            updated_at=_parse_datetime(rec["updated_at"]),
        ),
    )


@router.patch(
    "/businesses/{business_id}",
    response_model=APIResponse[BusinessResponse],
    summary="Update business status or details",
)
async def update_business(
    business_id: str,
    update_in: BusinessUpdate,
    current_user: Any = Depends(get_current_user),
):
    db = _get_db()
    rec = verify_business_ownership(db, business_id, current_user)
    now = datetime.now(timezone.utc)
    updates = {k: v for k, v in update_in.model_dump().items() if v is not None}
    updates["updated_at"] = now.isoformat()

    if db is not None:
        try:
            res = db.table("businesses").update(updates).eq("id", business_id).execute()
            if res.data:
                rec = res.data[0]
                return APIResponse(
                    success=True,
                    data=BusinessResponse(
                        id=str(rec["id"]),
                        entrepreneur_id=str(rec["entrepreneur_id"]),
                        name=rec["name"],
                        status=rec["status"],
                        domain=rec["domain"],
                        product_or_service=rec["product_or_service"],
                        business_model=rec.get("business_model"),
                        description=rec.get("description"),
                        target_customer=rec.get("target_customer"),
                        intended_market=rec.get("intended_market"),
                        scale=rec.get("scale") or "micro",
                        created_at=_parse_datetime(rec["created_at"]),
                        updated_at=_parse_datetime(rec["updated_at"]),
                    ),
                    message="Business updated successfully.",
                )
        except VyaparMitraException:
            raise
        except Exception as e:
            logger.warning(f"Database update business failed: {e}")
            if is_production():
                raise ServiceUnavailableException("Database service unavailable.")

    if business_id in _OFFLINE_BUSINESSES:
        for k, v in updates.items():
            rec[k] = v
        rec["updated_at"] = now
        return APIResponse(
            success=True,
            data=BusinessResponse(**rec),
            message="Business updated (sandbox mode).",
        )

    raise ResourceNotFoundException("Business", business_id)


@router.post(
    "/businesses/{business_id}/versions",
    response_model=APIResponse[BusinessVersionResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create a new version to preserve traceability of refined business assumptions",
)
async def create_business_version(
    business_id: str,
    ver_in: BusinessVersionCreate,
    current_user: Any = Depends(get_current_user),
):
    db = _get_db()
    rec = verify_business_ownership(db, business_id, current_user)
    now = datetime.now(timezone.utc)
    ver_id = str(uuid.uuid4())

    if db is not None:
        try:
            # Query existing latest version number to avoid collision (HIGH-3)
            latest_res = (
                db.table("business_versions")
                .select("version_number")
                .eq("business_id", business_id)
                .order("version_number", desc=True)
                .limit(1)
                .execute()
            )
            next_version = (latest_res.data[0]["version_number"] + 1) if (latest_res.data and latest_res.data[0].get("version_number")) else 1

            insert_dict = {
                "id": ver_id,
                "business_id": business_id,
                "version_number": next_version,
                "business_definition": ver_in.business_definition,
                "assumptions": ver_in.assumptions,
                "source": ver_in.source,
                "created_at": now.isoformat(),
                "confirmed_at": now.isoformat(),
            }
            res = db.table("business_versions").insert(insert_dict).execute()
            if res.data:
                rec = res.data[0]
                return APIResponse(
                    success=True,
                    data=BusinessVersionResponse(
                        id=str(rec["id"]),
                        business_id=str(rec["business_id"]),
                        version_number=rec["version_number"],
                        business_definition=rec["business_definition"],
                        assumptions=rec.get("assumptions") or {},
                        source=rec["source"],
                        created_at=_parse_datetime(rec["created_at"]),
                        confirmed_at=_parse_datetime(rec["confirmed_at"]) if rec.get("confirmed_at") else None,
                    ),
                    message="New business version recorded.",
                )
        except VyaparMitraException:
            raise
        except Exception as e:
            logger.warning(f"Database insert business_versions failed: {e}")
            if is_production():
                raise ServiceUnavailableException("Database service unavailable.")

    # Offline/sandbox
    if business_id in _OFFLINE_BUSINESSES:
        existing_versions = _OFFLINE_VERSIONS.get(business_id, [])
        next_ver_num = max([v.get("version_number", 0) for v in existing_versions], default=0) + 1
        ver_rec = {
            "id": ver_id,
            "business_id": business_id,
            "version_number": next_ver_num,
            "business_definition": ver_in.business_definition,
            "assumptions": ver_in.assumptions,
            "source": ver_in.source,
            "created_at": now,
            "confirmed_at": now,
        }
        if business_id not in _OFFLINE_VERSIONS:
            _OFFLINE_VERSIONS[business_id] = []
        _OFFLINE_VERSIONS[business_id].append(ver_rec)

        return APIResponse(
            success=True,
            data=BusinessVersionResponse(**ver_rec),
            message="New business version recorded (sandbox mode).",
        )

    raise ResourceNotFoundException("Business", business_id)
