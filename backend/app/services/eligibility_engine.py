import logging
from typing import Any, Dict, List, Optional, Tuple
from app.adapters.supabase_adapter import supabase_adapter
from app.schemas.recommendation import RuleEvaluationResult
from app.services.rule_engine import RuleEngine

logger = logging.getLogger(__name__)

# Static fallback rules for development / offline sandbox testing
FALLBACK_SCHEME_RULES: Dict[str, List[Dict[str, Any]]] = {
    "PMEGP": [
        {"field_name": "age", "operator": ">=", "expected_value": 18, "is_mandatory": True, "error_message": "Applicant must be at least 18 years of age."},
        {"field_name": "business_status", "operator": "equals", "expected_value": "new", "is_mandatory": True, "error_message": "PMEGP is applicable only for new (greenfield) enterprises."},
        {"field_name": "previous_government_subsidy", "operator": "equals", "expected_value": False, "is_mandatory": True, "error_message": "Applicant must not have availed previous government subsidy for this project."},
        {"field_name": "total_project_cost", "operator": "<=", "expected_value": 5000000, "is_mandatory": True, "error_message": "Total project cost exceeds PMEGP maximum ceiling of ₹50 Lakhs."},
    ],
    "MUDRA_SHISHU": [
        {"field_name": "age", "operator": ">=", "expected_value": 18, "is_mandatory": True, "error_message": "Applicant must be at least 18 years of age."},
        {"field_name": "loan_required", "operator": "<=", "expected_value": 50000, "is_mandatory": True, "error_message": "MUDRA Shishu loan limit is up to ₹50,000."},
    ],
    "MUDRA_KISHORE": [
        {"field_name": "age", "operator": ">=", "expected_value": 18, "is_mandatory": True, "error_message": "Applicant must be at least 18 years of age."},
        {"field_name": "loan_required", "operator": "between", "expected_value": [50001, 500000], "is_mandatory": True, "error_message": "MUDRA Kishore covers loans between ₹50,001 and ₹5,00,000."},
    ],
    "MUDRA_TARUN": [
        {"field_name": "age", "operator": ">=", "expected_value": 18, "is_mandatory": True, "error_message": "Applicant must be at least 18 years of age."},
        {"field_name": "loan_required", "operator": "between", "expected_value": [500001, 1000000], "is_mandatory": True, "error_message": "MUDRA Tarun covers loans between ₹5,00,001 and ₹10,00,000."},
    ],
    "STANDUP_INDIA": [
        {"field_name": "age", "operator": ">=", "expected_value": 18, "is_mandatory": True, "error_message": "Applicant must be at least 18 years of age."},
        {"field_name": "target_category", "operator": "in", "expected_value": ["sc", "st", "woman"], "is_mandatory": True, "error_message": "Stand-Up India is exclusively for SC, ST, or Woman entrepreneurs."},
        {"field_name": "business_status", "operator": "equals", "expected_value": "new", "is_mandatory": True, "error_message": "Stand-Up India requires the enterprise to be greenfield (first venture)."},
        {"field_name": "loan_required", "operator": "between", "expected_value": [1000000, 10000000], "is_mandatory": True, "error_message": "Stand-Up India facilitates loans between ₹10 Lakhs and ₹1 Crore."},
    ],
    "PM_SVANIDHI": [
        {"field_name": "age", "operator": ">=", "expected_value": 18, "is_mandatory": True, "error_message": "Applicant must be at least 18 years of age."},
        {"field_name": "rural_or_urban", "operator": "equals", "expected_value": "urban", "is_mandatory": True, "error_message": "PM SVANidhi is dedicated to urban street vendors."},
        {"field_name": "loan_required", "operator": "<=", "expected_value": 50000, "is_mandatory": True, "error_message": "PM SVANidhi initial micro-credit limit is up to ₹50,000."},
    ],
}


class EligibilityEngine:
    """
    Evaluates candidate schemes against generic database rules.
    Enforces mandatory rule gating: Any mandatory failure immediately marks the candidate as ineligible.
    """

    @classmethod
    def evaluate_candidates(
        cls,
        candidate_schemes: List[Dict[str, Any]],
        profile: Dict[str, Any],
    ) -> List[Dict[str, Any]]:
        evaluated_schemes = []

        for scheme in candidate_schemes:
            scheme_code = scheme.get("scheme_code", "")
            scheme_id = str(scheme.get("id") or "")
            
            # Load rules from DB or fallback
            rules = cls._fetch_rules_for_scheme(scheme_id, scheme_code)

            matched_rules: List[RuleEvaluationResult] = []
            failed_rules: List[RuleEvaluationResult] = []
            missing_rules: List[RuleEvaluationResult] = []

            has_mandatory_failure = False
            has_missing_mandatory = False

            for rule in rules:
                res = RuleEngine.evaluate_rule(rule, profile)

                if res.actual_value is None:
                    missing_rules.append(res)
                    if res.is_mandatory:
                        has_missing_mandatory = True
                elif res.passed:
                    matched_rules.append(res)
                else:
                    failed_rules.append(res)
                    if res.is_mandatory:
                        has_mandatory_failure = True

            # Determine eligibility status
            total_rules = len(rules)
            if total_rules == 0:
                eligibility_status = "conditionally_eligible"
                elig_score = 0.70
            elif has_mandatory_failure:
                eligibility_status = "ineligible"
                elig_score = 0.0
            elif has_missing_mandatory:
                eligibility_status = "needs_information"
                elig_score = 0.40
            else:
                passed_count = len(matched_rules)
                elig_score = round(passed_count / max(1, total_rules), 4)
                if len(failed_rules) == 0 and len(missing_rules) == 0:
                    eligibility_status = "eligible"
                else:
                    eligibility_status = "conditionally_eligible"

            evaluated_item = dict(scheme)
            evaluated_item["eligibility_status"] = eligibility_status
            evaluated_item["eligibility_score"] = elig_score
            evaluated_item["matched_rules"] = matched_rules
            evaluated_item["failed_rules"] = failed_rules
            evaluated_item["missing_rules"] = missing_rules
            
            evaluated_schemes.append(evaluated_item)

        return evaluated_schemes

    @classmethod
    def _fetch_rules_for_scheme(cls, scheme_id: str, scheme_code: str) -> List[Dict[str, Any]]:
        client = supabase_adapter.admin_client or supabase_adapter.client
        if client is not None and scheme_id:
            try:
                res = client.table("scheme_rules").select("*").eq("scheme_id", scheme_id).execute()
                if res.data and len(res.data) > 0:
                    return res.data
            except Exception as e:
                logger.warning(f"Failed to fetch rules for scheme {scheme_code} ({e}); using fallback.")

        return FALLBACK_SCHEME_RULES.get(scheme_code, [])
