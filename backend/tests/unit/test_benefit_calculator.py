import pytest
from app.services.benefit_calculator import BenefitCalculator


def test_pmegp_rural_special_category_calculation():
    scheme = {"scheme_code": "PMEGP", "max_loan_limit": 5000000.0, "max_subsidy_pct": 35.0}
    profile = {
        "total_project_cost": 400000.0,
        "own_capital": 50000.0,
        "loan_required": 350000.0,
        "rural_or_urban": "rural",
        "social_category": "obc",
        "is_woman_entrepreneur": False,
        "business_type": "manufacturing",
    }
    estimate = BenefitCalculator.calculate(scheme, profile)
    # Special category in rural gets 35% subsidy
    assert estimate.subsidy_percentage == 35.0
    assert estimate.estimated_subsidy == 140000.0 # 35% of 400,000
    assert estimate.estimated_own_contribution == 20000.0 # 5% of 400,000
    assert estimate.effective_project_cost == 260000.0


def test_pmegp_urban_general_category_calculation():
    scheme = {"scheme_code": "PMEGP", "max_loan_limit": 5000000.0, "max_subsidy_pct": 35.0}
    profile = {
        "total_project_cost": 500000.0,
        "own_capital": 60000.0,
        "rural_or_urban": "urban",
        "social_category": "general",
        "is_woman_entrepreneur": False,
        "business_type": "manufacturing",
    }
    estimate = BenefitCalculator.calculate(scheme, profile)
    # General category in urban gets 15% subsidy and 10% own contribution
    assert estimate.subsidy_percentage == 15.0
    assert estimate.estimated_subsidy == 75000.0 # 15% of 500,000
    assert estimate.estimated_own_contribution == 50000.0 # 10% of 500,000
    assert estimate.effective_project_cost == 425000.0


def test_mudra_shishu_benefit_calculation():
    scheme = {"scheme_code": "MUDRA_SHISHU", "max_loan_limit": 50000.0}
    profile = {
        "total_project_cost": 45000.0,
        "own_capital": 5000.0,
        "loan_required": 40000.0,
    }
    estimate = BenefitCalculator.calculate(scheme, profile)
    assert estimate.estimated_subsidy == 0.0
    assert estimate.estimated_loan == 40000.0
    assert estimate.effective_project_cost == 45000.0


def test_standup_india_benefit_calculation():
    scheme = {"scheme_code": "STANDUP_INDIA", "max_loan_limit": 10000000.0}
    profile = {
        "total_project_cost": 2000000.0,
        "own_capital": 300000.0,
        "loan_required": 1700000.0,
        "social_category": "woman",
        "is_woman_entrepreneur": True,
    }
    estimate = BenefitCalculator.calculate(scheme, profile)
    assert estimate.estimated_loan == 1700000.0
    assert estimate.estimated_own_contribution == 300000.0 # 15% of 20 Lakhs
