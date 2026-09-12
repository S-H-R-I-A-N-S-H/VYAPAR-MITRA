import uuid
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import get_current_user


client = TestClient(app)

MOCK_USER_ID = str(uuid.uuid4())


# Dependency override fixture for test authentication
@pytest.fixture
def auth_user():
    def override_get_current_user():
        return {
            "sub": MOCK_USER_ID,
            "email": "test_entrepreneur@vyapar.in",
            "role": "authenticated",
        }

    app.dependency_overrides[get_current_user] = override_get_current_user
    yield MOCK_USER_ID
    app.dependency_overrides.pop(get_current_user, None)


def test_get_profile_unauthorized():
    # Without auth token, should return 401
    response = client.get("/api/v1/profile")
    assert response.status_code == 401
    data = response.json()
    assert data["success"] is False
    assert data["error_code"] == "UNAUTHORIZED"


def test_create_and_get_profile(auth_user):
    payload = {
        "full_name": "Ramesh Patil",
        "preferred_language": "hi",
        "voice_enabled": True,
        "location": {
            "state": "Maharashtra",
            "district": "Pune",
            "town_or_village": "Baramati",
            "pincode": "413102",
            "latitude": 18.15,
            "longitude": 74.58
        },
        "available_capital": 150000.0,
        "skills": ["dairy_farming", "milk_testing"],
        "interests": ["dairy_processing", "cattle_feed"],
        "risk_preference": "moderate",
        "scheme_category": "obc",
        "consent_recorded": True
    }

    # 1. Create profile
    post_res = client.post("/api/v1/profile", json=payload)
    assert post_res.status_code in [200, 201]
    res_json = post_res.json()
    assert res_json["success"] is True
    profile = res_json["data"]
    assert profile["full_name"] == "Ramesh Patil"
    assert profile["available_capital"] == 150000.0
    assert "dairy_farming" in profile["skills"]

    # 2. Get profile
    get_res = client.get("/api/v1/profile")
    assert get_res.status_code == 200
    get_json = get_res.json()
    assert get_json["success"] is True
    assert get_json["data"]["full_name"] == "Ramesh Patil"
    assert get_json["data"]["user_id"] == auth_user


def test_update_profile(auth_user):
    update_payload = {
        "available_capital": 200000.0,
        "skills": ["dairy_farming", "milk_testing", "cheese_making"]
    }
    patch_res = client.patch("/api/v1/profile", json=update_payload)
    assert patch_res.status_code == 200
    patch_json = patch_res.json()
    assert patch_json["success"] is True
    assert patch_json["data"]["available_capital"] == 200000.0
    assert "cheese_making" in patch_json["data"]["skills"]


def test_create_and_get_location(auth_user):
    loc_payload = {
        "state": "Madhya Pradesh",
        "district": "Indore",
        "town_or_village": "Mhow",
        "pincode": "453441",
        "latitude": 22.55,
        "longitude": 75.76
    }
    loc_res = client.post("/api/v1/locations", json=loc_payload)
    assert loc_res.status_code in [200, 201]
    loc_json = loc_res.json()
    assert loc_json["success"] is True
    loc_id = loc_json["data"]["id"]
    assert loc_id is not None
    assert loc_json["data"]["town_or_village"] == "Mhow"

    # Get location by id
    get_loc_res = client.get(f"/api/v1/locations/{loc_id}")
    assert get_loc_res.status_code == 200
    assert get_loc_res.json()["data"]["district"] == "Indore"
