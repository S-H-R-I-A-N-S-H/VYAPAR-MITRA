import uuid
import pytest
from app.core.security import get_current_user
from app.main import app


@pytest.fixture
def auth_user():
    user_id = str(uuid.uuid4())

    def override_get_current_user():
        return {
            "sub": user_id,
            "id": user_id,
            "email": "schemes_test@vyapar.in",
            "role": "authenticated",
        }

    app.dependency_overrides[get_current_user] = override_get_current_user
    yield user_id
    app.dependency_overrides.pop(get_current_user, None)


def test_schemes_endpoints_unauthorized(client):
    """Verify schemes endpoints reject unauthenticated requests with 401 (HIGH-4a & T5)."""
    res_list = client.get("/api/v1/schemes/")
    assert res_list.status_code == 401

    res_match = client.post("/api/v1/schemes/match", json={})
    assert res_match.status_code == 401


def test_list_schemes_endpoint(client, auth_user):
    """Verify GET /api/v1/schemes/ returns all active government schemes from database."""
    response = client.get("/api/v1/schemes/")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert len(data["data"]) == 5
    scheme_codes = [s["scheme_code"] for s in data["data"]]
    assert "PMEGP" in scheme_codes
    assert "MUDRA_SHISHU" in scheme_codes
    assert "STANDUP_INDIA" in scheme_codes


def test_match_schemes_endpoint(client, auth_user):
    """Verify POST /api/v1/schemes/match calculates scheme eligibility."""
    payload = {
        "project_cost": 250000.0,
        "own_capital": 25000.0,
        "domain": "Manufacturing",
        "state": "Bihar",
        "district": "Patna",
        "category": "obc",
        "gender": "female",
    }
    response = client.post("/api/v1/schemes/match", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert len(data["data"]) > 0
    # Woman entrepreneur in manufacturing with 2.5L should match Mudra Kishore and PMEGP
    matched_names = [s["official_name"] for s in data["data"]]
    assert any("MUDRA" in name for name in matched_names)

