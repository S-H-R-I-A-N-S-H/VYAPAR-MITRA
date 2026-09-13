from typing import Any, Dict, Optional


class ProfileNormalizer:
    """
    Standardizes and normalizes entrepreneur, business, and financial inputs into an
    audit-ready canonical profile dictionary for deterministic rule evaluation.
    """

    @classmethod
    def normalize(
        cls,
        entrepreneur: Optional[Dict[str, Any]] = None,
        location: Optional[Dict[str, Any]] = None,
        eligibility_profile: Optional[Dict[str, Any]] = None,
        business: Optional[Dict[str, Any]] = None,
        overrides: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        ent = entrepreneur or {}
        loc = location or {}
        elig = eligibility_profile or {}
        biz = business or {}
        ovr = overrides or {}

        # 1. Demographics & Basics
        if "age" in ovr:
            age = ovr["age"]
        else:
            age = ent.get("age") if ent.get("age") is not None else 28

        gender = str(ovr.get("gender") or elig.get("gender") or ent.get("gender") or "male").strip().lower()
        education = str(ovr.get("education") or ent.get("education") or "10th_pass").strip().lower()
        social_category = str(
            ovr.get("social_category")
            or ovr.get("scheme_category")
            or ovr.get("category")
            or elig.get("category")
            or ent.get("scheme_category")
            or "general"
        ).strip().lower()
        
        # 2. Location
        state = str(ovr.get("state") or loc.get("state") or "Madhya Pradesh").strip()
        district = str(ovr.get("district") or loc.get("district") or "Indore").strip()
        town_or_village = str(ovr.get("town_or_village") or loc.get("town_or_village") or "Sanwer").strip()
        rural_or_urban = str(
            ovr.get("rural_or_urban")
            or loc.get("rural_or_urban")
            or ent.get("rural_or_urban")
            or "rural"
        ).strip().lower()

        # 3. Business Context
        business_name = str(ovr.get("business_name") or biz.get("name") or "Micro Enterprise").strip()
        business_activity = str(
            ovr.get("business_activity")
            or biz.get("product_or_service")
            or biz.get("business_activity")
            or "Food Processing"
        ).strip()
        business_type = str(
            ovr.get("business_type")
            or biz.get("domain")
            or biz.get("business_type")
            or "manufacturing"
        ).strip().lower()
        if any(w in business_type for w in ["manufact", "produc", "process", "mill", "oil", "food"]):
            normalized_business_type = "manufacturing"
        elif any(w in business_type for w in ["trad", "retail", "shop", "kirana", "vendor"]):
            normalized_business_type = "trading"
        else:
            normalized_business_type = "service"

        business_status = str(
            ovr.get("business_status")
            or biz.get("business_status")
            or biz.get("status")
            or "new"
        ).strip().lower()
        if business_status in ["idea", "validating", "planned", "new"]:
            normalized_business_status = "new"
        elif business_status in ["operating", "existing"]:
            normalized_business_status = "existing"
        else:
            normalized_business_status = "expansion"

        sector = str(ovr.get("sector") or biz.get("domain") or "Agri-Processing").strip()
        years_in_business = float(ovr.get("years_in_business") or biz.get("years_in_business") or 0.0)
        annual_turnover = float(ovr.get("annual_turnover") or biz.get("annual_turnover") or 0.0)
        number_of_employees = int(ovr.get("number_of_employees") or biz.get("number_of_employees") or 1)
        experience_years = float(ovr.get("experience_years") or ent.get("experience_years") or 2.0)
        occupation = str(ovr.get("occupation") or ent.get("occupation") or "Micro-entrepreneur").strip()

        # 4. Financial Parameters
        total_project_cost = float(
            ovr.get("total_project_cost")
            or biz.get("total_project_cost")
            or 250000.0
        )
        own_capital = float(
            ovr.get("own_capital")
            or ovr.get("available_capital")
            or biz.get("own_capital")
            or ent.get("available_capital")
            or 50000.0
        )
        loan_required = float(
            ovr.get("loan_required")
            or biz.get("loan_required")
            or max(0.0, total_project_cost - own_capital)
        )
        existing_loans = bool(ovr.get("existing_loans") or biz.get("existing_loans") or False)
        existing_loan_amount = float(ovr.get("existing_loan_amount") or biz.get("existing_loan_amount") or 0.0)
        monthly_emi = float(ovr.get("monthly_emi") or biz.get("monthly_emi") or 0.0)
        annual_income = float(ovr.get("annual_income") or ent.get("annual_income") or 120000.0)
        working_capital_requirement = float(
            ovr.get("working_capital_requirement") or biz.get("working_capital_requirement") or 50000.0
        )
        machinery_equipment_cost = float(
            ovr.get("machinery_equipment_cost") or biz.get("machinery_equipment_cost") or 150000.0
        )

        # 5. Government Benefit History
        previous_government_subsidy = bool(
            ovr.get("previous_government_subsidy")
            or ent.get("previous_government_subsidy")
            or False
        )
        previous_government_loan = bool(
            ovr.get("previous_government_loan")
            or ent.get("previous_government_loan")
            or False
        )
        previously_used_schemes = list(
            ovr.get("previously_used_schemes")
            or ent.get("previously_used_schemes")
            or []
        )

        # 6. Sensitive / Affirmative Statuses
        is_woman_entrepreneur = bool(
            ovr.get("is_woman_entrepreneur")
            or elig.get("is_woman_entrepreneur")
            or gender == "female"
            or social_category == "woman"
        )
        disability_category = ovr.get("disability_category") or elig.get("disability_category")
        minority_category = ovr.get("minority_category") or elig.get("minority_category")
        ex_serviceman_status = bool(
            ovr.get("ex_serviceman_status") or elig.get("ex_serviceman_status") or False
        )
        is_greenfield = bool(
            ovr.get("is_greenfield")
            or biz.get("is_greenfield")
            or normalized_business_status == "new"
        )

        # Combined target categories for easy membership check
        categories_set = {social_category}
        if is_woman_entrepreneur:
            categories_set.add("woman")
        if disability_category or social_category == "ph":
            categories_set.add("ph")
        if minority_category or social_category == "minority":
            categories_set.add("minority")
        if ex_serviceman_status or social_category == "ex_servicemen":
            categories_set.add("ex_servicemen")

        normalized = {
            "age": int(age) if age is not None else None,
            "gender": gender,
            "education": education,
            "social_category": social_category,
            "target_category": list(categories_set),
            "state": state,
            "district": district,
            "town_or_village": town_or_village,
            "rural_or_urban": rural_or_urban,
            "occupation": occupation,
            "experience_years": experience_years,
            "annual_income": annual_income,
            "business_name": business_name,
            "business_activity": business_activity,
            "business_type": normalized_business_type,
            "business_status": normalized_business_status,
            "sector": sector,
            "years_in_business": years_in_business,
            "annual_turnover": annual_turnover,
            "number_of_employees": number_of_employees,
            "is_greenfield": is_greenfield,
            "total_project_cost": total_project_cost,
            "project_cost": total_project_cost, # Alias
            "own_capital": own_capital,
            "loan_required": loan_required,
            "loan_amount": loan_required, # Alias
            "existing_loans": existing_loans,
            "existing_loan_amount": existing_loan_amount,
            "monthly_emi": monthly_emi,
            "working_capital_requirement": working_capital_requirement,
            "machinery_equipment_cost": machinery_equipment_cost,
            "previous_government_subsidy": previous_government_subsidy,
            "previous_government_loan": previous_government_loan,
            "previously_used_schemes": previously_used_schemes,
            "is_woman_entrepreneur": is_woman_entrepreneur,
            "disability_category": disability_category,
            "minority_category": minority_category,
            "ex_serviceman_status": ex_serviceman_status,
        }

        return normalized
