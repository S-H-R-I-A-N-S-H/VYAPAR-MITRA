from typing import List
from app.schemas.schemes import MatchedScheme, SchemeMatchRequest


class SchemeMatcher:
    """
    Deterministic rule-based evaluator for Indian Government and MSME schemes.
    Does not allow hallucinations in loan ceilings, subsidy percentages, or criteria.
    """

    @classmethod
    def evaluate(cls, req: SchemeMatchRequest) -> List[MatchedScheme]:
        matches: List[MatchedScheme] = []
        cost = req.project_cost
        cat = (req.category or "general").lower()
        is_special_cat = cat in ["sc", "st", "obc", "woman", "minority", "ph"]

        # 1. PMEGP (Prime Minister's Employment Generation Programme)
        # Manufacturing up to 50 Lakhs, Service up to 20 Lakhs
        # Subsidy: 15% (Gen Urban), 25% (Gen Rural / Special Urban), 35% (Special Rural)
        subsidy_pct = 35.0 if is_special_cat else 25.0  # Defaulting rural context
        max_limit = 5000000.0 if req.domain.lower() in ["manufacturing", "production", "processing"] else 2000000.0

        if cost <= max_limit:
            subsidy_est = round(cost * (subsidy_pct / 100.0), 2)
            matches.append(
                MatchedScheme(
                    scheme_id="PMEGP",
                    official_name="Prime Minister's Employment Generation Programme (PMEGP)",
                    authority="KVIC / Ministry of MSME",
                    max_loan_limit=max_limit,
                    max_subsidy_pct=subsidy_pct,
                    subsidy_amount_estimate=subsidy_est,
                    interest_rate_subsidy_pct=0.0,
                    eligibility_status="eligible",
                    rationale=f"Eligible for up to {subsidy_pct:.0f}% credit-linked capital subsidy in rural areas.",
                    key_conditions=[
                        "Beneficiary must be 18+ years of age.",
                        "Minimum 8th pass for manufacturing projects above ₹10 Lakhs.",
                        "Own contribution: 5% for special categories, 10% for general category.",
                    ],
                    official_portal_url="https://www.kviconline.gov.in/pmegpeportal/",
                )
            )

        # 2. Pradhan Mantri MUDRA Yojana (PMMY)
        # Shishu: up to ₹50,000 | Kishore: ₹50,001 to ₹5,00,000 | Tarun: ₹5,00,001 to ₹10,00,000
        if cost <= 1000000.0:
            if cost <= 50000.0:
                tier = "Shishu"
            elif cost <= 500000.0:
                tier = "Kishore"
            else:
                tier = "Tarun"

            matches.append(
                MatchedScheme(
                    scheme_id=f"MUDRA_{tier.upper()}",
                    official_name=f"Pradhan Mantri MUDRA Yojana ({tier})",
                    authority="MUDRA / Department of Financial Services",
                    max_loan_limit=1000000.0,
                    max_subsidy_pct=0.0,
                    subsidy_amount_estimate=0.0,
                    interest_rate_subsidy_pct=0.0,
                    eligibility_status="eligible",
                    rationale=f"Collateral-free micro-credit under MUDRA {tier} tier.",
                    key_conditions=[
                        "No collateral required.",
                        "No processing fee for Shishu and Kishore loans.",
                        "Available for non-farm income-generating micro activities.",
                    ],
                    official_portal_url="https://www.mudra.org.in/",
                )
            )

        # 3. Stand-Up India (For SC/ST and Women Entrepreneurs)
        if cat in ["sc", "st", "woman"] and cost >= 1000000.0 and cost <= 10000000.0:
            matches.append(
                MatchedScheme(
                    scheme_id="STANDUP_INDIA",
                    official_name="Stand-Up India Scheme",
                    authority="SIDBI / Ministry of Finance",
                    max_loan_limit=10000000.0,
                    max_subsidy_pct=0.0,
                    subsidy_amount_estimate=0.0,
                    eligibility_status="eligible",
                    rationale="Bank loans between ₹10 Lakh and ₹1 Crore to SC/ST or Women greenfield borrowers.",
                    key_conditions=[
                        "Greenfield enterprise only (first-time venture).",
                        "Borrower must not be in default to any bank or NBFC.",
                    ],
                    official_portal_url="https://www.standupmitra.in/",
                )
            )

        return matches
