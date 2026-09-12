import uuid
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import get_current_user


client = TestClient(app)
MOCK_USER_ID = str(uuid.uuid4())


@pytest.fixture
def auth_user():
    def override_get_current_user():
        return {
            "sub": MOCK_USER_ID,
            "email": "recommendation_user@vyapar.in",
            "role": "authenticated",
        }

    app.dependency_overrides[get_current_user] = override_get_current_user
    yield MOCK_USER_ID
    app.dependency_overrides.pop(get_current_user, None)


def test_recommendation_unauthorized():
    res = client.get(f"/api/v1/businesses/{uuid.uuid4()}/recommendation")
    assert res.status_code == 401


def test_generate_final_recommendation_and_action_plan(auth_user):
    # 1. Create a business
    biz_res = client.post(
        "/api/v1/businesses",
        json={
            "name": "Baramati Organic Ghee",
            "domain": "Dairy",
            "product_or_service": "Desi Cow A2 Ghee",
            "description": "Farm-fresh cultured A2 ghee packed in 500ml glass jars."
        }
    )
    biz_id = biz_res.json()["data"]["id"]

    # 2. Create financial scenario
    client.post(
        "/api/v1/finance/scenarios",
        json={
            "business_id": biz_id,
            "scenario_name": "Base Plan",
            "total_project_cost": 250000.0,
            "own_capital": 50000.0,
            "annual_interest_rate_pct": 9.5,
            "tenure_months": 36,
            "projected_monthly_revenue": 45000.0,
            "projected_monthly_operating_cost": 22000.0
        }
    )

    # 3. Request final synthesis recommendation
    rec_res = client.get(f"/api/v1/businesses/{biz_id}/recommendation")
    assert rec_res.status_code == 200
    rec_data = rec_res.json()["data"]
    assert "verdict" in rec_data
    assert rec_data["verdict"] in [
        "PROCEED_WITH_PILOT",
        "NEEDS_MORE_EVIDENCE",
        "CAUTION_FINANCIAL_STRESS",
        "PIVOT",
    ]
    assert "swot_analysis" in rec_data
    assert len(rec_data["four_week_action_plan"]) == 4
    assert "week" in rec_data["four_week_action_plan"][0]
    assert len(rec_data["identified_risks_and_mitigations"]) >= 1
