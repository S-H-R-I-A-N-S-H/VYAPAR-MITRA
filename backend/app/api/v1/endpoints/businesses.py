from datetime import datetime, timezone
import logging
import uuid
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, status

from app.adapters.supabase_adapter import supabase_adapter
from app.api.v1.endpoints.opportunities import _OFFLINE_BUSINESSES, _OFFLINE_VERSIONS
from app.core.errors import ResourceNotFoundException
from app.core.security import get_current_user
from app.schemas.business import (
    BusinessCreate,
    BusinessResponse,
    BusinessUpdate,
    BusinessVersionCreate,
    BusinessVersionResponse,
)
from app.schemas.common import APIResponse

logger = logging.getLogger(__name__)

router = APIRouter()


def _get_db():
    return supabase_adapter.admin_client or supabase_adapter.client


@router.post(
    "/businesses",
    response_model=APIResponse[BusinessResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create a new business idea",
)
async def create_business(
    biz_in: BusinessCreate,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    user_id = str(current_user.get("sub") or current_user.get("id"))
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
                        created_at=datetime.fromisoformat(rec["created_at"]),
                        updated_at=datetime.fromisoformat(rec["updated_at"]),
                    ),
                    message="Business idea created successfully.",
                )
        except Exception as e:
            logger.warning(f"Failed to create business in database: {e}")

    biz_record = {
        "id": biz_id,
        "entrepreneur_id": user_id,
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
async def list_businesses(current_user: Dict[str, Any] = Depends(get_current_user)):
    user_id = str(current_user.get("sub") or current_user.get("id"))
    db = _get_db()
    result_list = []

    if db is not None:
        try:
            ent_res = db.table("entrepreneurs").select("id").eq("user_id", user_id).execute()
            if ent_res.data:
                entrepreneur_id = str(ent_res.data[0]["id"])
                res = db.table("businesses").select("*").eq("entrepreneur_id", entrepreneur_id).execute()
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
                            created_at=datetime.fromisoformat(rec["created_at"]),
                            updated_at=datetime.fromisoformat(rec["updated_at"]),
                        )
                    )
                return APIResponse(success=True, data=result_list)
        except Exception as e:
            logger.warning(f"Database list businesses failed: {e}")

    # Fallback to offline store
    for b_id, rec in _OFFLINE_BUSINESSES.items():
        if rec.get("entrepreneur_id") == user_id:
            result_list.append(BusinessResponse(**rec))

    return APIResponse(success=True, data=result_list)


@router.get(
    "/businesses/{business_id}",
    response_model=APIResponse[BusinessResponse],
    summary="Get business details by ID",
)
async def get_business(
    business_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    db = _get_db()
    if db is not None:
        try:
            res = db.table("businesses").select("*").eq("id", business_id).execute()
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
                        created_at=datetime.fromisoformat(rec["created_at"]),
                        updated_at=datetime.fromisoformat(rec["updated_at"]),
                    ),
                )
        except Exception as e:
            logger.warning(f"Database get business failed: {e}")

    if business_id in _OFFLINE_BUSINESSES:
        return APIResponse(
            success=True,
            data=BusinessResponse(**_OFFLINE_BUSINESSES[business_id]),
        )

    raise ResourceNotFoundException("Business", business_id)


@router.patch(
    "/businesses/{business_id}",
    response_model=APIResponse[BusinessResponse],
    summary="Update business status or details",
)
async def update_business(
    business_id: str,
    update_in: BusinessUpdate,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    db = _get_db()
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
                        created_at=datetime.fromisoformat(rec["created_at"]),
                        updated_at=datetime.fromisoformat(rec["updated_at"]),
                    ),
                    message="Business updated successfully.",
                )
        except Exception as e:
            logger.warning(f"Database update business failed: {e}")

    if business_id in _OFFLINE_BUSINESSES:
        rec = _OFFLINE_BUSINESSES[business_id]
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
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    db = _get_db()
    now = datetime.now(timezone.utc)
    ver_id = str(uuid.uuid4())

    if db is not None:
        try:
            # Query existing version count
            count_res = db.table("business_versions").select("version_number").eq("business_id", business_id).execute()
            next_version = len(count_res.data) + 1 if count_res.data else 1

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
                        created_at=datetime.fromisoformat(rec["created_at"]),
                        confirmed_at=datetime.fromisoformat(rec["confirmed_at"]) if rec.get("confirmed_at") else None,
                    ),
                    message="New business version recorded.",
                )
        except Exception as e:
            logger.warning(f"Database insert business_versions failed: {e}")

    # Offline/sandbox
    existing_versions = _OFFLINE_VERSIONS.get(business_id, [])
    next_ver_num = len(existing_versions) + 1
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
