import pytest
from app.schemas.recommendation import RecommendationRequest
from app.services.recommendation_service import RecommendationService


def test_persona_1_young_new_entrepreneur():
    """Young new entrepreneur (age 24, new business, manufacturing, rural, 2.5L cost)."""
    req = RecommendationRequest(
        override_profile={
            "age": 24,
            "business_status": "new",
            "business_type": "manufacturing",
            "rural_or_urban": "rural",
            "social_category": "general",
            "total_project_cost": 250000.0,
            "own_capital": 50000.0,
            "loan_required": 200000.0,
            "previous_government_subsidy": False,
        }
    )
    result = RecommendationService.run_recommendation(user_id="persona-1", request=req)
    assert result.eligible_count > 0
    # PMEGP should be top eligible with subsidy
    pmegp = next((r for r in result.recommendations if r.scheme_code == "PMEGP"), None)
    assert pmegp is not None
    assert pmegp.eligibility_status == "eligible"
    assert pmegp.benefit_estimate.estimated_subsidy > 0


def test_persona_2_existing_business_owner():
    """Existing business owner (operating for 3 years, not greenfield)."""
    req = RecommendationRequest(
        override_profile={
            "age": 35,
            "business_status": "existing",
            "is_greenfield": False,
            "years_in_business": 3.0,
            "total_project_cost": 400000.0,
            "loan_required": 300000.0,
            "previous_government_subsidy": False,
        }
    )
    result = RecommendationService.run_recommendation(user_id="persona-2", request=req)
    # PMEGP requires 'new' business_status, so it must fail mandatory rule and be marked ineligible
    pmegp = next((r for r in result.recommendations if r.scheme_code == "PMEGP"), None)
    assert pmegp is not None
    assert pmegp.eligibility_status == "ineligible"
    # MUDRA Kishore should be eligible for existing expansion
    mudra_kishore = next((r for r in result.recommendations if r.scheme_code == "MUDRA_KISHORE"), None)
    assert mudra_kishore is not None
    assert mudra_kishore.eligibility_status == "eligible"


def test_persona_3_sc_st_entrepreneur():
    """SC/ST entrepreneur applying for greenfield venture."""
    req = RecommendationRequest(
        override_profile={
            "age": 29,
            "social_category": "sc",
            "business_status": "new",
            "rural_or_urban": "rural",
            "total_project_cost": 1500000.0,
            "loan_required": 1200000.0,
            "previous_government_subsidy": False,
        }
    )
    result = RecommendationService.run_recommendation(user_id="persona-3", request=req)
    # Stand-Up India should be eligible (SC/ST + greenfield + 10L-1Cr)
    standup = next((r for r in result.recommendations if r.scheme_code == "STANDUP_INDIA"), None)
    assert standup is not None
    assert standup.eligibility_status == "eligible"


def test_persona_4_woman_entrepreneur():
    """Woman entrepreneur applying for greenfield venture."""
    req = RecommendationRequest(
        override_profile={
            "age": 32,
            "gender": "female",
            "social_category": "woman",
            "is_woman_entrepreneur": True,
            "business_status": "new",
            "rural_or_urban": "rural",
            "total_project_cost": 2000000.0,
            "loan_required": 1600000.0,
            "previous_government_subsidy": False,
        }
    )
    result = RecommendationService.run_recommendation(user_id="persona-4", request=req)
    standup = next((r for r in result.recommendations if r.scheme_code == "STANDUP_INDIA"), None)
    assert standup is not None
    assert standup.eligibility_status == "eligible"


def test_persona_5_rural_entrepreneur():
    """Rural entrepreneur gets maximum PMEGP 35% subsidy for special category."""
    req = RecommendationRequest(
        override_profile={
            "age": 27,
            "rural_or_urban": "rural",
            "social_category": "obc",
            "business_status": "new",
            "business_type": "manufacturing",
            "total_project_cost": 300000.0,
            "own_capital": 50000.0,
            "loan_required": 250000.0,
            "previous_government_subsidy": False,
        }
    )
    result = RecommendationService.run_recommendation(user_id="persona-5", request=req)
    pmegp = next((r for r in result.recommendations if r.scheme_code == "PMEGP"), None)
    assert pmegp is not None
    assert pmegp.eligibility_status == "eligible"
    assert pmegp.benefit_estimate.subsidy_percentage == 35.0


def test_persona_6_high_project_cost_entrepreneur():
    """High project cost (> 50 Lakhs) exceeding PMEGP ceiling."""
    req = RecommendationRequest(
        override_profile={
            "age": 40,
            "total_project_cost": 7500000.0, # 75 Lakhs
            "loan_required": 6000000.0,
            "business_status": "new",
            "previous_government_subsidy": False,
        }
    )
    result = RecommendationService.run_recommendation(user_id="persona-6", request=req)
    pmegp = next((r for r in result.recommendations if r.scheme_code == "PMEGP"), None)
    assert pmegp is not None
    assert pmegp.eligibility_status == "ineligible"


def test_persona_7_entrepreneur_with_existing_government_subsidy():
    """Entrepreneur who previously availed a government subsidy."""
    req = RecommendationRequest(
        override_profile={
            "age": 30,
            "business_status": "new",
            "previous_government_subsidy": True, # Has prior subsidy
            "total_project_cost": 300000.0,
            "loan_required": 250000.0,
        }
    )
    result = RecommendationService.run_recommendation(user_id="persona-7", request=req)
    pmegp = next((r for r in result.recommendations if r.scheme_code == "PMEGP"), None)
    assert pmegp is not None
    assert pmegp.eligibility_status == "ineligible"


def test_persona_8_incomplete_profile():
    """Entrepreneur with missing age attribute (must not assume true, flagged as needs_information)."""
    req = RecommendationRequest(
        override_profile={
            "age": None,
            "business_status": "new",
            "total_project_cost": 250000.0,
            "loan_required": 200000.0,
        }
    )
    result = RecommendationService.run_recommendation(user_id="persona-8", request=req)
    # Since age is missing, schemes checking age must flag needs_information
    pmegp = next((r for r in result.recommendations if r.scheme_code == "PMEGP"), None)
    assert pmegp is not None
    assert pmegp.eligibility_status == "needs_information"
