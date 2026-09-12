from app.schemas.schemes import SchemeMatchRequest
from app.services.scheme_matcher import SchemeMatcher


def test_scheme_matcher_mudra_shishu():
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


def test_scheme_matcher_standup_india_for_women():
    req = SchemeMatchRequest(
        project_cost=1500000.0,  # 15 Lakhs
        own_capital=300000.0,
        domain="Manufacturing",
        state="Uttar Pradesh",
        category="woman",
    )
    matches = SchemeMatcher.evaluate(req)
    scheme_ids = [m.scheme_id for m in matches]
    assert "STANDUP_INDIA" in scheme_ids
    assert "PMEGP" in scheme_ids
