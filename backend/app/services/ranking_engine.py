from typing import Any, Dict, List, Optional
from app.schemas.recommendation import SchemeBenefitEstimate


class RankingEngine:
    """
    Ranks schemes using multi-dimensional scoring weights:
    - Eligibility Match: 40%
    - Business Relevance: 25%
    - Financial Fit: 15%
    - Location Match: 10%
    - Expected Benefit: 10%

    Strict Architectural Gate:
    Ineligible schemes (failed mandatory rules) are gated and can never outrank eligible schemes.
    """

    DEFAULT_WEIGHTS = {
        "eligibility": 0.40,
        "business_relevance": 0.25,
        "financial_fit": 0.15,
        "location": 0.10,
        "benefit_value": 0.10,
    }

    def __init__(self, weights: Optional[Dict[str, float]] = None):
        self.weights = weights or dict(self.DEFAULT_WEIGHTS)
        # Normalize weights to sum to 1.0
        total = sum(self.weights.values())
        if total > 0:
            self.weights = {k: v / total for k, v in self.weights.items()}

    def compute_scores(
        self,
        scheme: Dict[str, Any],
        profile: Dict[str, Any],
        benefit: SchemeBenefitEstimate,
    ) -> Dict[str, float]:
        elig_status = scheme.get("eligibility_status", "ineligible")
        elig_score = float(scheme.get("eligibility_score") or 0.0)
        semantic_score = float(scheme.get("semantic_score") or 0.5)

        # 1. Business Relevance Score
        biz_types = [str(x).lower() for x in (scheme.get("target_business_types") or [])]
        sectors = [str(x).lower() for x in (scheme.get("target_sectors") or [])]
        p_biz_type = str(profile.get("business_type") or "").lower()
        p_sector = str(profile.get("sector") or "").lower()

        biz_score = 0.50
        if p_biz_type in biz_types:
            biz_score += 0.25
        if any(p_sector in s for s in sectors):
            biz_score += 0.25
        biz_score = min(1.0, max(0.2, (biz_score + semantic_score) / 2.0))

        # 2. Financial Fit Score
        project_cost = float(profile.get("total_project_cost") or 250000.0)
        max_loan = float(scheme.get("max_loan_limit") or 10000000.0)
        loan_required = float(profile.get("loan_required") or 200000.0)

        if loan_required <= max_loan and project_cost <= (max_loan * 1.5):
            financial_score = 1.0
        elif loan_required <= (max_loan * 2.0):
            financial_score = 0.60
        else:
            financial_score = 0.20

        # 3. Location Match Score
        target_states = [str(x).upper() for x in (scheme.get("target_states") or ["ALL"])]
        p_state = str(profile.get("state") or "").upper()
        if "ALL" in target_states or p_state in target_states:
            location_score = 1.0
        else:
            location_score = 0.30

        # 4. Benefit Value Score
        if benefit.estimated_subsidy > 0:
            subsidy_ratio = min(1.0, benefit.estimated_subsidy / max(1.0, project_cost))
            benefit_score = min(1.0, 0.50 + (subsidy_ratio * 0.50))
        elif benefit.estimated_loan > 0:
            benefit_score = 0.70
        else:
            benefit_score = 0.30

        # Combined Weighted Score
        raw_score = (
            (self.weights["eligibility"] * elig_score)
            + (self.weights["business_relevance"] * biz_score)
            + (self.weights["financial_fit"] * financial_score)
            + (self.weights["location"] * location_score)
            + (self.weights["benefit_value"] * benefit_score)
        )

        # Gate enforcement: Ineligible schemes are severely penalized (max 0.25) so they never rank above eligible
        if elig_status == "ineligible":
            final_suitability = round(min(0.25, raw_score * 0.25), 4)
        elif elig_status == "needs_information":
            final_suitability = round(min(0.65, raw_score * 0.80), 4)
        else:
            final_suitability = round(min(1.0, raw_score), 4)

        return {
            "suitability_score": final_suitability,
            "semantic_score": round(semantic_score, 4),
            "eligibility_score": round(elig_score, 4),
            "business_relevance_score": round(biz_score, 4),
            "financial_fit_score": round(financial_score, 4),
            "location_fit_score": round(location_score, 4),
        }
