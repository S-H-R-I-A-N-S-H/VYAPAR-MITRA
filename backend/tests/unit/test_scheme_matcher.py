from app.schemas.schemes import SchemeMatchRequest
from app.services.scheme_matcher import SchemeMatcher


def test_scheme_matcher_mudra_shishu():
    """Cost <= 50,000 matches Mudra Shishu."""
    req = SchemeMatchRequest(
        project_cost=45000.0,
        own_capital=5000.0,
        domain="Retail",
        state="Maharashtra",
        category="general",
    )
    matches = SchemeMatcher.evaluate(req)
    scheme_ids = [m.scheme_id for m in matches]
    assert "MUDRA_SHISHU" in scheme_ids
    assert "PMEGP" in scheme_ids


def test_scheme_matcher_mudra_kishore_boundaries():
    """Cost between 50,001 and 5,00,000 matches Mudra Kishore."""
    req_lower = SchemeMatchRequest(
        project_cost=50001.0,
        own_capital=5000.0,
        domain="Food Processing",
        state="Punjab",
        category="general",
    )
    matches_lower = SchemeMatcher.evaluate(req_lower)
    assert "MUDRA_KISHORE" in [m.scheme_id for m in matches_lower]

    req_upper = SchemeMatchRequest(
        project_cost=500000.0,
        own_capital=50000.0,
        domain="Food Processing",
        state="Punjab",
        category="general",
    )
    matches_upper = SchemeMatcher.evaluate(req_upper)
    assert "MUDRA_KISHORE" in [m.scheme_id for m in matches_upper]


def test_scheme_matcher_mudra_tarun_boundary():
    """Cost between 5,00,001 and 10,00,000 matches Mudra Tarun."""
    req = SchemeMatchRequest(
        project_cost=750000.0,
        own_capital=100000.0,
        domain="Textiles",
        state="Gujarat",
        category="general",
    )
    matches = SchemeMatcher.evaluate(req)
    scheme_ids = [m.scheme_id for m in matches]
    assert "MUDRA_TARUN" in scheme_ids
    assert "MUDRA_KISHORE" not in scheme_ids
    assert "MUDRA_SHISHU" not in scheme_ids


def test_scheme_matcher_over_10_lakh_ineligible_for_mudra():
    """Projects exceeding 10 Lakhs cannot receive Mudra micro-loans."""
    req = SchemeMatchRequest(
        project_cost=1500000.0,
        own_capital=200000.0,
        domain="Manufacturing",
        state="Tamil Nadu",
        category="general",
    )
    matches = SchemeMatcher.evaluate(req)
    scheme_ids = [m.scheme_id for m in matches]
    assert not any("MUDRA" in s for s in scheme_ids)


def test_scheme_matcher_standup_india_eligibility_matrix():
    """Stand-Up India is strictly for SC/ST/Women with project cost between 10L and 100L."""
    # 1. Eligible woman entrepreneur with 20 Lakhs
    req_woman = SchemeMatchRequest(
        project_cost=2000000.0,
        own_capital=300000.0,
        domain="Manufacturing",
        state="Uttar Pradesh",
        category="woman",
    )
    matches = SchemeMatcher.evaluate(req_woman)
    assert "STANDUP_INDIA" in [m.scheme_id for m in matches]

    # 2. Ineligible general male with 20 Lakhs
    req_gen = SchemeMatchRequest(
        project_cost=2000000.0,
        own_capital=300000.0,
        domain="Manufacturing",
        state="Uttar Pradesh",
        category="general",
        gender="male",
    )
    matches_gen = SchemeMatcher.evaluate(req_gen)
    assert "STANDUP_INDIA" not in [m.scheme_id for m in matches_gen]

    # 3. Ineligible woman under 10 Lakh threshold (e.g. 5 Lakhs)
    req_woman_low = SchemeMatchRequest(
        project_cost=500000.0,
        own_capital=50000.0,
        domain="Services",
        state="Rajasthan",
        category="woman",
    )
    matches_low = SchemeMatcher.evaluate(req_woman_low)
    assert "STANDUP_INDIA" not in [m.scheme_id for m in matches_low]


def test_scheme_matcher_pmegp_domain_ceilings():
    """PMEGP limit is 50L for Manufacturing and 20L for Services."""
    # 25 Lakhs in Service domain exceeds 20L ceiling -> should not match PMEGP
    req_service = SchemeMatchRequest(
        project_cost=2500000.0,
        own_capital=500000.0,
        domain="Services",
        state="Karnataka",
        category="general",
    )
    matches_service = SchemeMatcher.evaluate(req_service)
    assert "PMEGP" not in [m.scheme_id for m in matches_service]

    # 25 Lakhs in Manufacturing domain is within 50L ceiling -> matches PMEGP
    req_mfg = SchemeMatchRequest(
        project_cost=2500000.0,
        own_capital=500000.0,
        domain="Manufacturing",
        state="Karnataka",
        category="general",
    )
    matches_mfg = SchemeMatcher.evaluate(req_mfg)
    assert "PMEGP" in [m.scheme_id for m in matches_mfg]
    # General category subsidy should be 25%
    pmegp_match = next(m for m in matches_mfg if m.scheme_id == "PMEGP")
    assert pmegp_match.max_subsidy_pct == 25.0


def test_scheme_matcher_pmegp_special_category_subsidy():
    """Special category entrepreneurs receive higher (35%) capital subsidy under PMEGP."""
    req_special = SchemeMatchRequest(
        project_cost=1000000.0,
        own_capital=50000.0,
        domain="Manufacturing",
        state="Odisha",
        category="sc",
    )
    matches = SchemeMatcher.evaluate(req_special)
    pmegp_match = next(m for m in matches if m.scheme_id == "PMEGP")
    assert pmegp_match.max_subsidy_pct == 35.0
    assert pmegp_match.subsidy_amount_estimate == 350000.0
