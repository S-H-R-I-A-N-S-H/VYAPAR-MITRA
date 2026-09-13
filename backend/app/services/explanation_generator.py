from typing import Any, Dict, List
from app.schemas.recommendation import RuleEvaluationResult, SchemeBenefitEstimate, SchemeExplanation


class ExplanationGenerator:
    """
    Generates transparent, auditable natural-language explanations directly from deterministic
    engine results. Never fabricates criteria or benefits.
    """

    @classmethod
    def generate(
        cls,
        scheme: Dict[str, Any],
        profile: Dict[str, Any],
        matched_rules: List[RuleEvaluationResult],
        failed_rules: List[RuleEvaluationResult],
        missing_rules: List[RuleEvaluationResult],
        benefit: SchemeBenefitEstimate,
    ) -> SchemeExplanation:
        official_name = str(scheme.get("official_name") or "Government Scheme")
        authority = str(scheme.get("authority") or "Implementing Ministry")
        portal_url = scheme.get("official_portal_url")
        status = scheme.get("eligibility_status", "eligible")

        # 1. Why selected
        biz_name = str(profile.get("business_name") or "Your Enterprise")
        biz_type = str(profile.get("business_type") or "enterprise")
        why_selected = (
            f"{official_name} was identified because {biz_name} operates in {biz_type} "
            f"and matches the target profile and financing parameters under {authority}."
        )

        # 2. Why eligible
        why_eligible: List[str] = []
        if status in ["eligible", "conditionally_eligible"]:
            for r in matched_rules:
                if r.field_name == "age":
                    why_eligible.append("Age requirement satisfied (18+ years).")
                elif r.field_name == "business_status":
                    why_eligible.append("Classified as a new (greenfield) enterprise.")
                elif r.field_name in ["total_project_cost", "project_cost"]:
                    why_eligible.append(f"Project cost of ₹{float(profile.get('total_project_cost', 0)):,.0f} is within the scheme ceiling.")
                elif r.field_name in ["loan_required", "loan_amount"]:
                    why_eligible.append("Loan requirement is within the eligible borrowing tier.")
                elif r.field_name == "target_category":
                    why_eligible.append(f"Affirmative social category qualification satisfied.")
                elif r.field_name == "previous_government_subsidy":
                    why_eligible.append("No prior conflicting government subsidy on record.")
                elif r.field_name == "rural_or_urban":
                    why_eligible.append(f"Location classification ({profile.get('rural_or_urban')}) matches scheme mandate.")
                else:
                    why_eligible.append(r.description or f"Condition for {r.field_name} satisfied.")
        elif status == "needs_information":
            why_eligible.append("Preliminary criteria match, but additional profile details are required to confirm final eligibility.")
        else:
            why_eligible.append("Scheme does not satisfy one or more mandatory eligibility conditions.")

        # 3. Passed and failed rule descriptions
        passed_rules_str = [r.description or f"{r.field_name}: passed" for r in matched_rules]
        failed_rules_str = [r.error_message or f"{r.field_name}: condition failed" for r in failed_rules]
        missing_info_str = [r.error_message or f"Please provide '{r.field_name}' to verify." for r in missing_rules]

        # 4. Summary Text
        if status == "eligible":
            summary = f"You satisfy all mandatory eligibility criteria for {official_name}."
        elif status == "conditionally_eligible":
            summary = f"You qualify for {official_name}, subject to standard bank documentation."
        elif status == "needs_information":
            summary = f"Additional information needed to confirm your eligibility for {official_name}."
        else:
            summary = f"Not currently eligible for {official_name} due to specific scheme boundaries."

        return SchemeExplanation(
            summary=summary,
            why_selected=why_selected,
            why_eligible=why_eligible,
            passed_rules=passed_rules_str,
            failed_rules=failed_rules_str,
            missing_information=missing_info_str,
            financial_breakdown=benefit.calculation_breakdown,
            official_source=authority,
            official_portal_url=portal_url,
            official_disclaimer=(
                "Estimated benefit calculations are based on published guidelines. "
                "Final sanction is subject to appraisal and approval by the participating financial institution/nodal agency."
            ),
        )
