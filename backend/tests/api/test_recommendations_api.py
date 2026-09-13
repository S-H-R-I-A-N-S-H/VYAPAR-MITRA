import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_post_recommendations_endpoint():
    payload = {
        "override_profile": {
            "age": 28,
            "rural_or_urban": "rural",
            "social_category": "obc",
            "business_status": "new",
            "business_type": "manufacturing",
            "total_project_cost": 300000.0,
            "own_capital": 50000.0,
            "loan_required": 250000.0,
            "previous_government_subsidy": False,
        }
    }
    response = client.post(
        "/api/v1/recommendations",
        json=payload,
        headers={"Authorization": "Bearer mock-user-test-001"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "recommendations" in data["data"]
    assert len(data["data"]["recommendations"]) > 0
    assert data["data"]["eligible_count"] >= 1


def test_get_latest_recommendations_endpoint():
    response = client.get(
        "/api/v1/recommendations/latest",
        headers={"Authorization": "Bearer mock-user-test-001"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "run_id" in data["data"]


def test_get_recommendation_by_id_endpoint():
    # First generate a run
    res = client.post(
        "/api/v1/recommendations",
        json={},
        headers={"Authorization": "Bearer mock-user-test-001"},
    )
    run_id = res.json()["data"]["run_id"]

    # Then retrieve it
    detail_res = client.get(
        f"/api/v1/recommendations/{run_id}",
        headers={"Authorization": "Bearer mock-user-test-001"},
    )
    assert detail_res.status_code == 200
    data = detail_res.json()
    assert data["success"] is True
    assert "run" in data["data"]
