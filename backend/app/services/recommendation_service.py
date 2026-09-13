from datetime import datetime, timezone
import logging
import uuid
from typing import Any, Dict, List, Optional

from app.adapters.supabase_adapter import supabase_adapter
from app.adapters.supabase_adapter import supabase_adapter
from app.schemas.recommendation import (
    RecommendationRequest,
    RecommendationRunResponse,
    SchemeRecommendationItem,
)
from app.services.benefit_calculator import BenefitCalculator
from app.services.eligibility_engine import EligibilityEngine
from app.services.explanation_generator import ExplanationGenerator
from app.services.profile_normalizer import ProfileNormalizer
from app.services.ranking_engine import RankingEngine
from app.services.semantic_retriever import SemanticRetriever

logger = logging.getLogger(__name__)

# Offline recommendation store
_OFFLINE_REC_RUNS: Dict[str, Dict[str, Any]] = {}
_OFFLINE_REC_ITEMS: Dict[str, List[Dict[str, Any]]] = {}


class RecommendationService:
    """
    Coordinates the complete Government Scheme Recommendation Pipeline.
    """

    @classmethod
    def run_recommendation(
        cls,
        user_id: str,
        request: RecommendationRequest,
    ) -> RecommendationRunResponse:
        db = supabase_adapter.admin_client or supabase_adapter.client
        now = datetime.now(timezone.utc)

        # 1. Fetch Profile Data from DB or offline stores
        ent_data: Dict[str, Any] = {}
        loc_data: Dict[str, Any] = {}
        elig_data: Dict[str, Any] = {}
        biz_data: Dict[str, Any] = {}

        if db is not None:
            try:
                # Entrepreneur
                e_res = db.table("entrepreneurs").select("*").eq("user_id", user_id).execute()
                if e_res.data:
                    ent_data = e_res.data[0]
                    # Location
                    if ent_data.get("location_id"):
                        l_res = db.table("locations").select("*").eq("id", ent_data["location_id"]).execute()
                        if l_res.data:
                            loc_data = l_res.data[0]
                    # Eligibility Profile
                    el_res = db.table("entrepreneur_eligibility_profile").select("*").eq("entrepreneur_id", ent_data["id"]).execute()
                    if el_res.data:
                        elig_data = el_res.data[0]
                    # Business
                    if request.business_id:
                        b_res = db.table("businesses").select("*").eq("id", request.business_id).execute()
                    else:
                        b_res = db.table("businesses").select("*").eq("entrepreneur_id", ent_data["id"]).order("created_at", desc=True).limit(1).execute()
                    if b_res.data:
                        biz_data = b_res.data[0]
            except Exception as e:
                logger.warning(f"Database read failed during recommendation: {e}")

        # Fallback to in-memory store if DB was empty or unconfigured
        from app.api.v1.endpoints.profile import _OFFLINE_PROFILES, _OFFLINE_LOCATIONS
        from app.api.v1.endpoints.opportunities import _OFFLINE_BUSINESSES

        if not ent_data and user_id in _OFFLINE_PROFILES:
            ent_data = _OFFLINE_PROFILES[user_id]
            if ent_data.get("location_id") in _OFFLINE_LOCATIONS:
                loc_data = _OFFLINE_LOCATIONS[ent_data["location_id"]]
        if not biz_data and request.business_id and request.business_id in _OFFLINE_BUSINESSES:
            biz_data = _OFFLINE_BUSINESSES[request.business_id]

        # 2. Normalize Profile
        profile_snapshot = ProfileNormalizer.normalize(
            entrepreneur=ent_data,
            location=loc_data,
            eligibility_profile=elig_data,
            business=biz_data,
            overrides=request.override_profile,
        )

        # 3. Retrieve Candidate Schemes (Semantic search / representation)
        candidates = SemanticRetriever.retrieve_candidates(profile_snapshot, top_k=20)

        # 4. Evaluate Hard Rules (Deterministic eligibility gating)
        evaluated_schemes = EligibilityEngine.evaluate_candidates(candidates, profile_snapshot)

        # 5. Calculate Benefits & Multi-Dimensional Ranking
        ranking_engine = RankingEngine()
        recommendation_items: List[SchemeRecommendationItem] = []

        for sch in evaluated_schemes:
            benefit_est = BenefitCalculator.calculate(sch, profile_snapshot)
            scores = ranking_engine.compute_scores(sch, profile_snapshot, benefit_est)
            
            explanation = ExplanationGenerator.generate(
                scheme=sch,
                profile=profile_snapshot,
                matched_rules=sch.get("matched_rules", []),
                failed_rules=sch.get("failed_rules", []),
                missing_rules=sch.get("missing_rules", []),
                benefit=benefit_est,
            )

            rec_item = SchemeRecommendationItem(
                scheme_id=str(sch.get("id") or uuid.uuid4()),
                scheme_code=sch.get("scheme_code", "SCHEME"),
                official_name=sch.get("official_name", "Government Scheme"),
                authority=sch.get("authority", "Ministry"),
                scheme_type=sch.get("scheme_type", "CENTRAL"),
                eligibility_status=sch.get("eligibility_status", "eligible"),
                suitability_score=scores["suitability_score"],
                semantic_score=scores["semantic_score"],
                eligibility_score=scores["eligibility_score"],
                business_relevance_score=scores["business_relevance_score"],
                financial_fit_score=scores["financial_fit_score"],
                location_fit_score=scores["location_fit_score"],
                matched_rules=sch.get("matched_rules", []),
                failed_rules=sch.get("failed_rules", []),
                missing_rules=sch.get("missing_rules", []),
                benefit_estimate=benefit_est,
                explanation=explanation,
                official_portal_url=sch.get("official_portal_url"),
                key_conditions=[
                    r.description or r.field_name
                    for r in sch.get("matched_rules", [])
                ],
            )
            recommendation_items.append(rec_item)

        # Sort recommendations by suitability_score descending
        recommendation_items.sort(key=lambda x: x.suitability_score, reverse=True)

        # 6. Save Recommendation Run & Items
        run_id = str(uuid.uuid4())
        ent_id = str(ent_data.get("id")) if ent_data.get("id") else user_id
        biz_id = str(biz_data.get("id")) if biz_data.get("id") else request.business_id

        if db is not None and ent_data.get("id"):
            try:
                run_payload = {
                    "id": run_id,
                    "entrepreneur_id": ent_data.get("id"),
                    "business_id": biz_data.get("id") if biz_data.get("id") else None,
                    "profile_snapshot": profile_snapshot,
                    "created_at": now.isoformat(),
                }
                db.table("recommendation_runs").insert(run_payload).execute()

                for r in recommendation_items:
                    item_payload = {
                        "recommendation_run_id": run_id,
                        "scheme_id": r.scheme_id,
                        "eligibility_status": r.eligibility_status,
                        "semantic_score": r.semantic_score,
                        "eligibility_score": r.eligibility_score,
                        "final_score": r.suitability_score,
                        "matched_rules": [m.model_dump() for m in r.matched_rules],
                        "failed_rules": [f.model_dump() for f in r.failed_rules],
                        "missing_rules": [mis.model_dump() for mis in r.missing_rules],
                        "estimated_subsidy": r.benefit_estimate.estimated_subsidy,
                        "estimated_loan": r.benefit_estimate.estimated_loan,
                        "explanation": r.explanation.model_dump(),
                        "created_at": now.isoformat(),
                    }
                    db.table("scheme_recommendations").insert(item_payload).execute()
            except Exception as e:
                logger.warning(f"Failed to persist recommendation run to Supabase ({e}); storing in memory.")

        # Offline caching
        _OFFLINE_REC_RUNS[run_id] = {
            "id": run_id,
            "entrepreneur_id": ent_id,
            "business_id": biz_id,
            "profile_snapshot": profile_snapshot,
            "created_at": now,
        }
        _OFFLINE_REC_ITEMS[run_id] = [r.model_dump() for r in recommendation_items]

        # Counts
        eligible_count = sum(1 for r in recommendation_items if r.eligibility_status == "eligible")
        needs_info_count = sum(1 for r in recommendation_items if r.eligibility_status == "needs_information")
        ineligible_count = sum(1 for r in recommendation_items if r.eligibility_status == "ineligible")

        return RecommendationRunResponse(
            run_id=run_id,
            entrepreneur_id=ent_id,
            business_id=biz_id,
            recommendations=recommendation_items,
            total_schemes_evaluated=len(recommendation_items),
            eligible_count=eligible_count,
            needs_info_count=needs_info_count,
            ineligible_count=ineligible_count,
            generated_at=now,
        )

    @classmethod
    def get_recommendation_by_id(cls, run_id: str) -> Optional[Dict[str, Any]]:
        db = supabase_adapter.admin_client or supabase_adapter.client
        if db is not None:
            try:
                r_res = db.table("recommendation_runs").select("*").eq("id", run_id).execute()
                if r_res.data:
                    run = r_res.data[0]
                    items_res = db.table("scheme_recommendations").select("*, schemes(*)").eq("recommendation_run_id", run_id).execute()
                    return {"run": run, "items": items_res.data or []}
            except Exception as e:
                logger.warning(f"Failed to get recommendation run from db: {e}")

        if run_id in _OFFLINE_REC_RUNS:
            return {
                "run": _OFFLINE_REC_RUNS[run_id],
                "items": _OFFLINE_REC_ITEMS.get(run_id, []),
            }
        return None
