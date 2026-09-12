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
            "email": "finance_user@vyapar.in",
            "role": "authenticated",
        }

    app.dependency_overrides[get_current_user] = override_get_current_user
    yield MOCK_USER_ID
    app.dependency_overrides.pop(get_current_user, None)


def test_finance_endpoints_unauthorized():
    res = client.post("/api/v1/finance/scenarios", json={"total_project_cost": 500000})
    assert res.status_code == 401


def test_financial_scenario_lifecycle_and_what_if_analysis(auth_user):
    # 1. Create a business first
    biz_res = client.post(
        "/api/v1/businesses",
        json={
            "name": "Baramati Dairy Farm",
            "domain": "Dairy",
            "product_or_service": "Milk & Ghee"
        }
    )
    biz_id = biz_res.json()["data"]["id"]

    # 2. Create financial scenario
    scenario_payload = {
        "business_id": biz_id,
        "scenario_name": "Base Realistic Plan",
        "total_project_cost": 500000.0,
        "own_capital": 100000.0,
        "annual_interest_rate_pct": 9.5,
        "tenure_months": 36,
        "projected_monthly_revenue": 60000.0,
        "projected_monthly_operating_cost": 30000.0
    }
    scen_res = client.post("/api/v1/finance/scenarios", json=scenario_payload)
    assert scen_res.status_code in [200, 201]
    scen_data = scen_res.json()["data"]
    scen_id = scen_data["id"]
    assert scen_data["simulation_result"]["is_affordable"] is True
    assert scen_data["simulation_result"]["monthly_emi"] > 0
    assert "explanation" in scen_data

    # 3. Get scenario
    get_res = client.get(f"/api/v1/finance/scenarios/{scen_id}")
    assert get_res.status_code == 200
    assert get_res.json()["data"]["scenario_name"] == "Base Realistic Plan"

    # 4. Run What-If Stress Analysis (e.g. 20% revenue drop)
    what_if_res = client.post(
        f"/api/v1/finance/scenarios/{scen_id}/what-if",
        json={"revenue_drop_pct": 20.0, "cost_increase_pct": 10.0}
    )
    assert what_if_res.status_code == 200
    what_if_data = what_if_res.json()["data"]
    assert "base_case" in what_if_data
    assert "stressed_case" in what_if_data
    assert what_if_data["stressed_case"]["monthly_profit"] < what_if_data["base_case"]["monthly_profit"]
