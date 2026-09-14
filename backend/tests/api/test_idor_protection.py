"""
backend/tests/api/test_idor_protection.py
Comprehensive multi-tenant isolation and IDOR (Insecure Direct Object Reference)
verification tests across all Vyapar Mitra resource endpoints.

Verifies that authenticated User B receives HTTP 403 Forbidden whenever attempting
to read, modify, or extend resources owned by User A.
"""
import uuid
import pytest
from fastapi.testclient import TestClient

from app.core.security import AuthenticatedUser, get_current_user
from app.main import app

client = TestClient(app)

USER_A_ID = str(uuid.uuid4())
USER_B_ID = str(uuid.uuid4())


def set_active_user(user_id: str, email: str = "user@vyapar.in"):
    user = AuthenticatedUser(
        user_id=user_id,
        email=email,
        role="authenticated",
        claims={"sub": user_id},
    )
    app.dependency_overrides[get_current_user] = lambda: user


@pytest.fixture(autouse=True)
def cleanup_overrides():
    yield
    app.dependency_overrides.pop(get_current_user, None)


@pytest.fixture
def user_a_resources():
    """Sets up a complete set of User A resources for IDOR testing."""
    set_active_user(USER_A_ID, "user_a@vyapar.in")

    # 1. Profile for User A
    prof_res = client.post(
        "/api/v1/profile",
        json={
            "full_name": "User A Entrepreneur",
            "preferred_language": "hi",
            "location": {
                "state": "Maharashtra",
                "district": "Pune",
                "town_or_village": "Baramati",
            },
            "available_capital": 200000.0,
            "skills": ["manufacturing"],
        },
    )
    assert prof_res.status_code in [200, 201]

    # 2. Business for User A
    biz_res = client.post(
        "/api/v1/businesses",
        json={
            "name": "User A Flour Mill",
            "domain": "Agro-processing",
            "product_or_service": "Whole Wheat Flour",
            "scale": "micro",
        },
    )
    assert biz_res.status_code in [200, 201]
    biz_id = biz_res.json()["data"]["id"]

    # 3. Interview Session for User A
    sess_res = client.post(
        "/api/v1/interviews",
        json={"language": "hi", "business_id": biz_id},
    )
    assert sess_res.status_code in [200, 201]
    session_id = sess_res.json()["data"]["id"]

    # 4. Location & Research Project for User A
    loc_res = client.post(
        "/api/v1/locations",
        json={"state": "Maharashtra", "district": "Pune", "town_or_village": "Baramati"},
    )
    loc_id = loc_res.json()["data"]["id"]

    proj_res = client.post(
        "/api/v1/research/projects",
        json={"business_id": biz_id, "location_id": loc_id},
    )
    assert proj_res.status_code in [200, 201]
    proj_id = proj_res.json()["data"]["id"]

    # 5. Survey under Research Project for User A
    survey_res = client.post(
        "/api/v1/surveys",
        json={
            "research_project_id": proj_id,
            "title": "Local Flour Consumption Survey",
            "target_respondent_type": "household",
            "questions": [
                {"question_text": "How many kg flour per month?", "question_type": "number"}
            ],
        },
    )
    assert survey_res.status_code in [200, 201]
    survey_id = survey_res.json()["data"]["id"]

    # 6. Financial Scenario for User A
    scen_res = client.post(
        "/api/v1/finance/scenarios",
        json={
            "business_id": biz_id,
            "scenario_name": "Base Plan",
            "total_project_cost": 200000.0,
            "own_capital": 50000.0,
            "annual_interest_rate_pct": 9.5,
            "tenure_months": 36,
            "projected_monthly_revenue": 40000.0,
            "projected_monthly_operating_cost": 20000.0,
        },
    )
    assert scen_res.status_code in [200, 201]
    scenario_id = scen_res.json()["data"]["id"]

    return {
        "biz_id": biz_id,
        "session_id": session_id,
        "proj_id": proj_id,
        "survey_id": survey_id,
        "scenario_id": scenario_id,
    }


def test_idor_business_access_forbidden(user_a_resources):
    """User B must be forbidden from reading, modifying, or synthesizing User A's business."""
    biz_id = user_a_resources["biz_id"]
    set_active_user(USER_B_ID, "user_b@vyapar.in")

    # 1. GET business
    res = client.get(f"/api/v1/businesses/{biz_id}")
    assert res.status_code == 403
    assert res.json()["error_code"] == "FORBIDDEN"

    # 2. PATCH business
    res = client.patch(f"/api/v1/businesses/{biz_id}", json={"name": "Hacked Name"})
    assert res.status_code == 403
    assert res.json()["error_code"] == "FORBIDDEN"

    # 3. POST new version
    res = client.post(
        f"/api/v1/businesses/{biz_id}/versions",
        json={"business_id": biz_id, "business_definition": "Takeover", "source": "USER"},
    )
    assert res.status_code == 403
    assert res.json()["error_code"] == "FORBIDDEN"

    # 4. Feasibility analysis
    res = client.post(f"/api/v1/businesses/{biz_id}/feasibility/analyze", json={})
    assert res.status_code == 403
    assert res.json()["error_code"] == "FORBIDDEN"

    # 5. Recommendation synthesis
    res = client.get(f"/api/v1/businesses/{biz_id}/recommendation")
    assert res.status_code == 403
    assert res.json()["error_code"] == "FORBIDDEN"


def test_idor_interview_session_access_forbidden(user_a_resources):
    """User B must be forbidden from injecting turns into User A's interview session."""
    session_id = user_a_resources["session_id"]
    set_active_user(USER_B_ID, "user_b@vyapar.in")

    res = client.post(
        f"/api/v1/interviews/{session_id}/messages",
        json={"content": "I am injecting a message into someone else's interview."},
    )
    assert res.status_code == 403
    assert res.json()["error_code"] == "FORBIDDEN"


def test_idor_research_project_access_forbidden(user_a_resources):
    """User B must be forbidden from viewing or attaching evidence to User A's research project."""
    proj_id = user_a_resources["proj_id"]
    set_active_user(USER_B_ID, "user_b@vyapar.in")

    # 1. GET research project
    res = client.get(f"/api/v1/research/projects/{proj_id}")
    assert res.status_code == 403
    assert res.json()["error_code"] == "FORBIDDEN"

    # 2. GET research project evidence
    res = client.get(f"/api/v1/research/projects/{proj_id}/evidence")
    assert res.status_code == 403
    assert res.json()["error_code"] == "FORBIDDEN"

    # 3. POST evidence item to project
    res = client.post(
        f"/api/v1/research/projects/{proj_id}/evidence",
        json={
            "claim": "Spurious evidence claim",
            "source_name": "Hacker",
            "source_type": "PRIMARY",
            "confidence_score": 0.5,
        },
    )
    assert res.status_code == 403
    assert res.json()["error_code"] == "FORBIDDEN"

    # 4. POST survey under User A's project
    res = client.post(
        "/api/v1/surveys",
        json={
            "research_project_id": proj_id,
            "title": "Unauthorized Survey",
            "target_respondent_type": "household",
            "questions": [],
        },
    )
    assert res.status_code == 403
    assert res.json()["error_code"] == "FORBIDDEN"


def test_idor_survey_access_forbidden(user_a_resources):
    """User B must be forbidden from viewing or submitting responses to User A's survey."""
    survey_id = user_a_resources["survey_id"]
    set_active_user(USER_B_ID, "user_b@vyapar.in")

    # 1. GET survey
    res = client.get(f"/api/v1/surveys/{survey_id}")
    assert res.status_code == 403
    assert res.json()["error_code"] == "FORBIDDEN"

    # 2. POST survey response
    res = client.post(
        f"/api/v1/surveys/{survey_id}/responses",
        json={
            "survey_id": survey_id,
            "respondent_identifier": "Intruder",
            "answers": {"test": "val"},
        },
    )
    assert res.status_code == 403
    assert res.json()["error_code"] == "FORBIDDEN"


def test_idor_financial_scenario_access_forbidden(user_a_resources):
    """User B must be forbidden from accessing, stress-testing, or creating scenarios on User A's business."""
    biz_id = user_a_resources["biz_id"]
    scenario_id = user_a_resources["scenario_id"]
    set_active_user(USER_B_ID, "user_b@vyapar.in")

    # 1. GET financial scenario
    res = client.get(f"/api/v1/finance/scenarios/{scenario_id}")
    assert res.status_code == 403
    assert res.json()["error_code"] == "FORBIDDEN"

    # 2. POST stress-test / what-if
    res = client.post(
        f"/api/v1/finance/scenarios/{scenario_id}/what-if",
        json={
            "revenue_shock_pct": -20.0,
            "cost_inflation_pct": 10.0,
            "interest_rate_delta_pct": 2.0,
        },
    )
    assert res.status_code == 403
    assert res.json()["error_code"] == "FORBIDDEN"

    # 3. POST new scenario referencing User A's business
    res = client.post(
        "/api/v1/finance/scenarios",
        json={
            "business_id": biz_id,
            "scenario_name": "Hostile Scenario",
            "total_project_cost": 100000.0,
            "own_capital": 20000.0,
            "annual_interest_rate_pct": 9.5,
            "tenure_months": 24,
            "projected_monthly_revenue": 25000.0,
            "projected_monthly_operating_cost": 15000.0,
        },
    )
    assert res.status_code == 403
    assert res.json()["error_code"] == "FORBIDDEN"
