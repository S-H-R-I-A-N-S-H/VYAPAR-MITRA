from datetime import datetime, timezone
import logging
import uuid
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, Field

from app.adapters.supabase_adapter import supabase_adapter
from app.core.security import get_current_user
from app.schemas.business import BusinessResponse
from app.schemas.common import APIResponse
from app.services.opportunity_generator import OpportunityGenerator
from app.services.prompt_service import OpportunityDiscoveryResponse

logger = logging.getLogger(__name__)

router = APIRouter()
opportunity_generator = OpportunityGenerator()

_OFFLINE_BUSINESSES: Dict[str, Dict[str, Any]] = {}
_OFFLINE_VERSIONS: Dict[str, List[Dict[str, Any]]] = {}


def _get_db():
    return supabase_adapter.admin_client or supabase_adapter.client


class OpportunityDiscoverInput(BaseModel):
    interview_id: Optional[str] = None
    location_id: Optional[str] = None
    skills: List[str] = Field(default_factory=list)
    capital: Optional[float] = None
    location: Optional[str] = None
    count: int = Field(default=3, ge=1, le=5)
    language: str = "en"


class OpportunitySelectInput(BaseModel):
    title: str
    domain: str
    summary: str
    estimated_capital: float


@router.post(
    "/opportunities/discover",
    response_model=APIResponse[OpportunityDiscoveryResponse],
    summary="Discover grounded, tailored micro-business opportunities",
)
async def discover_opportunities(
    req: OpportunityDiscoverInput,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    user_id = str(current_user.get("sub") or current_user.get("id"))
    db = _get_db()

    skills = list(req.skills)
    capital = req.capital
    location_name = req.location

    # Hydrate missing constraints from profile
    if db is not None:
        try:
            ent_res = db.table("entrepreneurs").select("*").eq("user_id", user_id).execute()
            if ent_res.data:
                profile = ent_res.data[0]
                if not skills and profile.get("skills"):
                    skills = profile["skills"]
                if capital is None and profile.get("available_capital"):
                    capital = float(profile["available_capital"])

                # Resolve location if available
                if not location_name and profile.get("location_id"):
                    loc_res = db.table("locations").select("*").eq("id", profile["location_id"]).execute()
                    if loc_res.data:
                        loc = loc_res.data[0]
                        location_name = f"{loc['town_or_village']}, {loc['district']}, {loc['state']}"
        except Exception as e:
            logger.warning(f"Failed to hydrate entrepreneur context: {e}")

    final_capital = capital if capital is not None else 50000.0
    final_location = location_name or "Rural Hub, India"

    result = await opportunity_generator.discover_opportunities(
        skills=skills,
        capital=final_capital,
        location=final_location,
        count=req.count,
        language=req.language,
    )

    return APIResponse(
        success=True,
        data=result,
        message=f"Discovered {len(result.opportunities)} viable business opportunities.",
    )


@router.post(
    "/opportunities/{opportunity_id}/select",
    response_model=APIResponse[BusinessResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Select opportunity and establish tracked business idea",
)
async def select_opportunity(
    opportunity_id: str,
    choice: OpportunitySelectInput,
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
                # Provision profile if missing
                new_ent = db.table("entrepreneurs").insert({
                    "user_id": user_id,
                    "full_name": "New Entrepreneur",
                    "available_capital": choice.estimated_capital,
                }).execute()
                if new_ent.data:
                    entrepreneur_id = str(new_ent.data[0]["id"])

            biz_insert = {
                "id": biz_id,
                "entrepreneur_id": entrepreneur_id,
                "name": choice.title,
                "status": "IDEA",
                "domain": choice.domain,
                "product_or_service": choice.title,
                "description": choice.summary,
                "created_at": now.isoformat(),
                "updated_at": now.isoformat(),
            }
            res = db.table("businesses").insert(biz_insert).execute()
            if res.data:
                rec = res.data[0]
                # Insert initial version 1 for immutable traceability
                db.table("business_versions").insert({
                    "business_id": biz_id,
                    "version_number": 1,
                    "business_definition": choice.summary,
                    "assumptions": {"estimated_capital": choice.estimated_capital, "origin_opportunity_id": opportunity_id},
                    "source": "AI_DRAFT",
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
                    message="Opportunity selected and business idea created.",
                )
        except Exception as e:
            logger.warning(f"Database opportunity selection insert failed: {e}")

    # Offline/mock store
    biz_record = {
        "id": biz_id,
        "entrepreneur_id": user_id,
        "name": choice.title,
        "status": "IDEA",
        "domain": choice.domain,
        "product_or_service": choice.title,
        "business_model": None,
        "description": choice.summary,
        "target_customer": None,
        "intended_market": None,
        "scale": "micro",
        "created_at": now,
        "updated_at": now,
    }
    _OFFLINE_BUSINESSES[biz_id] = biz_record
    _OFFLINE_VERSIONS[biz_id] = [{
        "id": str(uuid.uuid4()),
        "business_id": biz_id,
        "version_number": 1,
        "business_definition": choice.summary,
        "assumptions": {"estimated_capital": choice.estimated_capital},
        "source": "AI_DRAFT",
        "created_at": now,
        "confirmed_at": now,
    }]

    return APIResponse(
        success=True,
        data=BusinessResponse(**biz_record),
        message="Opportunity selected and business idea created (sandbox mode).",
    )
