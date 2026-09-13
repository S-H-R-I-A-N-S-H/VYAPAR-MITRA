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
            "email": "feasibility_user@vyapar.in",
            "role": "authenticated",
        }

    app.dependency_overrides[get_current_user] = override_get_current_user
    yield MOCK_USER_ID
    app.dependency_overrides.pop(get_current_user, None)


def test_feasibility_analyze_unauthorized():
    res = client.post(f"/api/v1/businesses/{uuid.uuid4()}/feasibility/analyze", json={})
    assert res.status_code == 401


def test_feasibility_analyze_successful(auth_user):
    # 1. Create a business
    biz_res = client.post(
        "/api/v1/businesses",
        json={
            "name": "Sanwer Mustard Oil Expeller",
            "domain": "Agriculture & Processing",
            "product_or_service": "Cold Pressed Mustard Oil",
            "description": "Micro oil expeller mill for rural households."
        }
    )
    assert biz_res.status_code == 201
    biz_id = biz_res.json()["data"]["id"]

    # 2. Trigger Feasibility Analysis
    analyze_res = client.post(
        f"/api/v1/businesses/{biz_id}/feasibility/analyze",
        json={
            "evidence_items": [
                {
                    "id": "ev_1",
                    "research_project_id": "proj_1",
                    "claim": "Local households report unserved demand for cold-pressed oil with stock-out waiting times",
                    "source_name": "Field Primary Survey",
                    "source_type": "FIELD_PRIMARY",
                    "confidence_score": 0.85,
                    "created_at": "2026-09-13T10:00:00Z"
                }
            ],
            "target_radius_km": 5.0,
            "financial_simulation": {
                "total_project_cost": 200000.0,
                "own_capital": 40000.0,
                "required_loan_amount": 160000.0,
                "monthly_emi": 5000.0,
                "total_interest_payable": 20000.0,
                "total_repayment_amount": 180000.0,
                "projected_monthly_profit": 12000.0,
                "net_cash_flow_after_emi": 7000.0,
                "debt_service_coverage_ratio": 2.4,
                "is_affordable": True,
                "affordability_risk_level": "safe",
                "affordability_rationale": "Healthy debt coverage ratio"
            }
        }
    )

    assert analyze_res.status_code == 200
    res_body = analyze_res.json()
    assert res_body["success"] is True
    data = res_body["data"]
    assert "overall_score" in data
    assert data["overall_score"] is not None
    assert data["grade"] in ["HIGHLY_FEASIBLE", "CONDITIONALLY_FEASIBLE", "MODERATE_RISK", "HIGH_RISK"]
    assert "financial_score_component" in data
    assert data["financial_score_component"] == 90.0
    assert "confidence_score" in data
