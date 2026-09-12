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
            "email": "biz_user@vyapar.in",
            "role": "authenticated",
        }

    app.dependency_overrides[get_current_user] = override_get_current_user
    yield MOCK_USER_ID
    app.dependency_overrides.pop(get_current_user, None)


def test_business_endpoints_unauthorized():
    res = client.get("/api/v1/businesses")
    assert res.status_code == 401


def test_discover_and_select_opportunity(auth_user):
    # 1. Discover opportunities
    discover_payload = {
        "capital": 100000.0,
        "location": "Indore, MP",
        "skills": ["food_processing", "spices"],
        "count": 3
    }
    disc_res = client.post("/api/v1/opportunities/discover", json=discover_payload)
    assert disc_res.status_code == 200
    disc_data = disc_res.json()["data"]
    assert len(disc_data["opportunities"]) >= 1
    selected_opp = disc_data["opportunities"][0]
    opp_id = selected_opp["id"] or "opp-123"

    # 2. Select opportunity -> creates business
    select_payload = {
        "title": selected_opp["title"],
        "domain": selected_opp["domain"],
        "summary": selected_opp["summary"],
        "estimated_capital": selected_opp["estimated_capital_required"]
    }
    select_res = client.post(f"/api/v1/opportunities/{opp_id}/select", json=select_payload)
    assert select_res.status_code in [200, 201]
    biz_data = select_res.json()["data"]
    biz_id = biz_data["id"]
    assert biz_data["status"] == "IDEA"
    assert biz_data["name"] == selected_opp["title"]

    # 3. List businesses
    list_res = client.get("/api/v1/businesses")
    assert list_res.status_code == 200
    items = list_res.json()["data"]
    assert any(b["id"] == biz_id for b in items)

    # 4. Get business detail
    get_res = client.get(f"/api/v1/businesses/{biz_id}")
    assert get_res.status_code == 200
    assert get_res.json()["data"]["name"] == selected_opp["title"]

    # 5. Update status
    patch_res = client.patch(f"/api/v1/businesses/{biz_id}", json={"status": "VALIDATING"})
    assert patch_res.status_code == 200
    assert patch_res.json()["data"]["status"] == "VALIDATING"

    # 6. Create version
    ver_payload = {
        "business_id": biz_id,
        "business_definition": "Refined business model targeting direct weekly haat stalls.",
        "assumptions": {"margin": 0.35, "spoilage_rate": 0.05},
        "source": "AI_REFINED"
    }
    ver_res = client.post(f"/api/v1/businesses/{biz_id}/versions", json=ver_payload)
    assert ver_res.status_code in [200, 201]
    assert ver_res.json()["data"]["version_number"] >= 1
