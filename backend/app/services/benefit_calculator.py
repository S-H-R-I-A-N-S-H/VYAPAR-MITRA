from typing import Any, Dict, List
from app.schemas.recommendation import SchemeBenefitEstimate


class BenefitCalculator:
    """
    Deterministic financial calculator for government scheme subsidies, loan ceilings,
    and entrepreneur margin money contributions.
    Never relies on AI/LLM for financial arithmetic.
    """

    @classmethod
    def calculate(
        cls,
        scheme: Dict[str, Any],
        profile: Dict[str, Any],
    ) -> SchemeBenefitEstimate:
        scheme_code = scheme.get("scheme_code", "")
        project_cost = float(profile.get("total_project_cost") or 250000.0)
        own_capital = float(profile.get("own_capital") or 50000.0)
        loan_required = float(profile.get("loan_required") or max(0.0, project_cost - own_capital))
        
        rural_or_urban = str(profile.get("rural_or_urban") or "rural").strip().lower()
        social_cat = str(profile.get("social_category") or "general").strip().lower()
        is_woman = bool(profile.get("is_woman_entrepreneur") or False)
        is_special_category = (
            social_cat in ["sc", "st", "obc", "woman", "minority", "ph", "ex_servicemen"]
            or is_woman
        )
        biz_type = str(profile.get("business_type") or "manufacturing").strip().lower()

        breakdown: List[str] = []
        estimated_subsidy = 0.0
        subsidy_pct = 0.0
        interest_subsidy_pct = 0.0
        own_contrib_pct = 10.0
        max_loan_limit = float(scheme.get("max_loan_limit") or 10000000.0)

        # -------------------------------------------------------------------
        # 1. PMEGP Subsidy Logic (MSME / KVIC Guidelines)
        # -------------------------------------------------------------------
        if scheme_code == "PMEGP":
            max_cost_allowed = 5000000.0 if biz_type == "manufacturing" else 2000000.0
            eligible_project_cost = min(project_cost, max_cost_allowed)

            if rural_or_urban == "rural":
                if is_special_category:
                    subsidy_pct = 35.0
                    own_contrib_pct = 5.0
                    breakdown.append("Special Category in Rural area qualifies for 35% capital subsidy.")
                    breakdown.append("Required entrepreneur own contribution is 5% of project cost.")
                else:
                    subsidy_pct = 25.0
                    own_contrib_pct = 10.0
                    breakdown.append("General Category in Rural area qualifies for 25% capital subsidy.")
                    breakdown.append("Required entrepreneur own contribution is 10% of project cost.")
            else: # Urban
                if is_special_category:
                    subsidy_pct = 25.0
                    own_contrib_pct = 5.0
                    breakdown.append("Special Category in Urban area qualifies for 25% capital subsidy.")
                    breakdown.append("Required entrepreneur own contribution is 5% of project cost.")
                else:
                    subsidy_pct = 15.0
                    own_contrib_pct = 10.0
                    breakdown.append("General Category in Urban area qualifies for 15% capital subsidy.")
                    breakdown.append("Required entrepreneur own contribution is 10% of project cost.")

            estimated_subsidy = round(eligible_project_cost * (subsidy_pct / 100.0), 2)
            required_own = round(eligible_project_cost * (own_contrib_pct / 100.0), 2)
            estimated_loan = round(eligible_project_cost - required_own, 2)
            effective_cost = round(project_cost - estimated_subsidy, 2)

            breakdown.append(f"Eligible Project Base: ₹{eligible_project_cost:,.2f}")
            breakdown.append(f"Estimated Government Margin Money (Grant): ₹{estimated_subsidy:,.2f}")
            breakdown.append(f"Estimated Bank Term Loan: ₹{estimated_loan:,.2f}")

            return SchemeBenefitEstimate(
                estimated_subsidy=estimated_subsidy,
                estimated_loan=estimated_loan,
                estimated_own_contribution=required_own,
                effective_project_cost=effective_cost,
                subsidy_percentage=subsidy_pct,
                interest_subsidy_pct=0.0,
                calculation_breakdown=breakdown,
                is_estimate=True,
            )

        # -------------------------------------------------------------------
        # 2. MUDRA Yojana (Shishu, Kishore, Tarun)
        # -------------------------------------------------------------------
        elif scheme_code.startswith("MUDRA"):
            if scheme_code == "MUDRA_SHISHU":
                cap = 50000.0
                tier_name = "Shishu"
            elif scheme_code == "MUDRA_KISHORE":
                cap = 500000.0
                tier_name = "Kishore"
            else:
                cap = 1000000.0
                tier_name = "Tarun"

            eligible_loan = min(loan_required, cap)
            required_own = max(0.0, project_cost - eligible_loan)
            effective_cost = project_cost

            breakdown.append(f"MUDRA {tier_name} provides 100% collateral-free micro-credit up to ₹{cap:,.2f}.")
            breakdown.append("No processing fee is levied on Shishu and Kishore loans.")
            breakdown.append(f"Eligible Micro-Loan: ₹{eligible_loan:,.2f}")

            return SchemeBenefitEstimate(
                estimated_subsidy=0.0,
                estimated_loan=eligible_loan,
                estimated_own_contribution=required_own,
                effective_project_cost=effective_cost,
                subsidy_percentage=0.0,
                interest_subsidy_pct=0.0,
                calculation_breakdown=breakdown,
                is_estimate=True,
            )

        # -------------------------------------------------------------------
        # 3. Stand-Up India (SIDBI)
        # -------------------------------------------------------------------
        elif scheme_code == "STANDUP_INDIA":
            eligible_loan = min(max(1000000.0, loan_required), 10000000.0)
            required_own = round(project_cost * 0.15, 2) # Min 15% margin money
            effective_cost = project_cost

            breakdown.append("Stand-Up India facilitates composite bank loans from ₹10 Lakhs up to ₹1 Crore.")
            breakdown.append("Minimum promoter contribution is 15% (can be converged with state subsidy schemes).")
            breakdown.append(f"Estimated Composite Loan Sanction: ₹{eligible_loan:,.2f}")

            return SchemeBenefitEstimate(
                estimated_subsidy=0.0,
                estimated_loan=eligible_loan,
                estimated_own_contribution=required_own,
                effective_project_cost=effective_cost,
                subsidy_percentage=0.0,
                interest_subsidy_pct=0.0,
                calculation_breakdown=breakdown,
                is_estimate=True,
            )

        # -------------------------------------------------------------------
        # 4. PM SVANidhi (Urban Micro-Credit & Interest Subsidy)
        # -------------------------------------------------------------------
        elif scheme_code == "PM_SVANIDHI":
            eligible_loan = min(loan_required, 50000.0)
            interest_subsidy_pct = 7.0
            breakdown.append("PM SVANidhi offers collateral-free working capital loan up to ₹50,000 in tranches.")
            breakdown.append("7.0% per annum interest subsidy credited directly to bank account on timely repayment.")
            breakdown.append(f"Eligible Working Capital Loan: ₹{eligible_loan:,.2f}")

            return SchemeBenefitEstimate(
                estimated_subsidy=0.0,
                estimated_loan=eligible_loan,
                estimated_own_contribution=0.0,
                effective_project_cost=project_cost,
                subsidy_percentage=0.0,
                interest_subsidy_pct=interest_subsidy_pct,
                calculation_breakdown=breakdown,
                is_estimate=True,
            )

        # -------------------------------------------------------------------
        # 5. Generic Fallback
        # -------------------------------------------------------------------
        eligible_loan = min(loan_required, max_loan_limit)
        subsidy_pct = float(scheme.get("max_subsidy_pct") or 0.0)
        estimated_subsidy = round(project_cost * (subsidy_pct / 100.0), 2)
        required_own = max(0.0, project_cost - estimated_subsidy - eligible_loan)

        breakdown.append(f"Standard credit assistance up to scheme limit of ₹{max_loan_limit:,.2f}.")
        if subsidy_pct > 0:
            breakdown.append(f"Applicable subsidy rate: {subsidy_pct}%.")

        return SchemeBenefitEstimate(
            estimated_subsidy=estimated_subsidy,
            estimated_loan=eligible_loan,
            estimated_own_contribution=required_own,
            effective_project_cost=round(project_cost - estimated_subsidy, 2),
            subsidy_percentage=subsidy_pct,
            interest_subsidy_pct=0.0,
            calculation_breakdown=breakdown,
            is_estimate=True,
        )
