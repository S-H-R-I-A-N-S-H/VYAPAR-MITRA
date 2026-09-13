import uuid
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import AuthenticatedUser, get_current_user


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


def test_direct_create_business_linked_to_entrepreneur(auth_user):
    # 1. First ensure user has an established entrepreneur profile
    prof_payload = {
        "full_name": "Ramesh Patil",
        "preferred_language": "hi",
        "voice_enabled": True,
        "location": {
            "state": "Maharashtra",
            "district": "Pune",
            "town_or_village": "Baramati",
            "pincode": "413102",
        },
        "available_capital": 250000.0,
        "skills": ["dairy_processing", "milk_distribution"],
    }
    prof_res = client.post("/api/v1/profile", json=prof_payload)
    assert prof_res.status_code in [200, 201]
    ent_id = prof_res.json()["data"]["id"]
    assert ent_id is not None

    # 2. Directly create business via POST /api/v1/businesses
    biz_payload = {
        "name": "Baramati Milk Chilling Hub",
        "domain": "dairy_processing",
        "product_or_service": "chilled_milk",
        "business_model": "b2b_wholesale",
        "description": "Bulk collection and chilling of dairy milk for regional dairy cooperatives.",
        "target_customer": "Regional cooperatives and local sweet shops",
        "intended_market": "Pune rural district",
        "scale": "micro",
    }
    create_res = client.post("/api/v1/businesses", json=biz_payload)
    assert create_res.status_code in [200, 201]
    create_data = create_res.json()["data"]
    biz_id = create_data["id"]
    assert biz_id is not None
    assert create_data["entrepreneur_id"] == ent_id
    assert create_data["name"] == "Baramati Milk Chilling Hub"
    assert create_data["status"] == "IDEA"

    # 3. Verify GET /api/v1/businesses/{id}
    get_res = client.get(f"/api/v1/businesses/{biz_id}")
    assert get_res.status_code == 200
    get_data = get_res.json()["data"]
    assert get_data["id"] == biz_id
    assert get_data["entrepreneur_id"] == ent_id
    assert get_data["product_or_service"] == "chilled_milk"


def test_multiple_businesses_per_entrepreneur(auth_user):
    # Create two businesses under the same entrepreneur
    biz_1_res = client.post("/api/v1/businesses", json={
        "name": "Baramati Fodder Store",
        "domain": "agriculture",
        "product_or_service": "cattle_fodder",
        "scale": "micro",
    })
    assert biz_1_res.status_code in [200, 201]
    biz_1_id = biz_1_res.json()["data"]["id"]
    ent_id_1 = biz_1_res.json()["data"]["entrepreneur_id"]

    biz_2_res = client.post("/api/v1/businesses", json={
        "name": "Baramati Organic Compost",
        "domain": "agriculture",
        "product_or_service": "vermicompost",
        "scale": "micro",
    })
    assert biz_2_res.status_code in [200, 201]
    biz_2_id = biz_2_res.json()["data"]["id"]
    ent_id_2 = biz_2_res.json()["data"]["entrepreneur_id"]

    assert biz_1_id != biz_2_id
    assert ent_id_1 == ent_id_2

    # Verify both appear in list_businesses
    list_res = client.get("/api/v1/businesses")
    assert list_res.status_code == 200
    b_ids = [b["id"] for b in list_res.json()["data"]]
    assert biz_1_id in b_ids
    assert biz_2_id in b_ids


def test_cross_user_isolation_ownership_enforcement(auth_user):
    # 1. User A creates a business
    create_res = client.post("/api/v1/businesses", json={
        "name": "User A Proprietary Venture",
        "domain": "crafts",
        "product_or_service": "handicrafts",
        "scale": "micro",
    })
    assert create_res.status_code in [200, 201]
    biz_a_id = create_res.json()["data"]["id"]

    # 2. Authenticate as User B
    user_b_id = str(uuid.uuid4())
    user_b = AuthenticatedUser(
        user_id=user_b_id,
        email="intruder_user_b@vyapar.in",
        role="authenticated",
        claims={"sub": user_b_id},
    )
    app.dependency_overrides[get_current_user] = lambda: user_b

    try:
        # User B should NOT be able to view User A's business
        get_res = client.get(f"/api/v1/businesses/{biz_a_id}")
        assert get_res.status_code == 403
        get_err = get_res.json()
        assert get_err["success"] is False
        assert get_err["error_code"] == "FORBIDDEN"

        # User B should NOT be able to update User A's business
        patch_res = client.patch(f"/api/v1/businesses/{biz_a_id}", json={"status": "ARCHIVED"})
        assert patch_res.status_code == 403
        assert patch_res.json()["error_code"] == "FORBIDDEN"

        # User B should NOT be able to append versions to User A's business
        ver_res = client.post(f"/api/v1/businesses/{biz_a_id}/versions", json={
            "business_id": biz_a_id,
            "business_definition": "Hostile takeover version",
            "assumptions": {},
            "source": "USER",
        })
        assert ver_res.status_code == 403
        assert ver_res.json()["error_code"] == "FORBIDDEN"

        # User B's list should NOT contain User A's business
        list_res = client.get("/api/v1/businesses")
        assert list_res.status_code == 200
        b_ids = [b["id"] for b in list_res.json()["data"]]
        assert biz_a_id not in b_ids

    finally:
        # Restore fixture override
        app.dependency_overrides[get_current_user] = lambda: {
            "sub": MOCK_USER_ID,
            "email": "biz_user@vyapar.in",
            "role": "authenticated",
        }


def test_business_not_found(auth_user):
    non_existent_id = str(uuid.uuid4())
    res = client.get(f"/api/v1/businesses/{non_existent_id}")
    assert res.status_code == 404
    assert res.json()["error_code"] == "RESOURCE_NOT_FOUND"


def test_discover_and_select_opportunity(auth_user):
    # 1. Discover opportunities
    discover_payload = {
        "capital": 100000.0,
        "location": "Indore, MP",
        "skills": ["food_processing", "spices"],
        "count": 3,
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
        "estimated_capital": selected_opp["estimated_capital_required"],
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
        "source": "AI_REFINED",
    }
    ver_res = client.post(f"/api/v1/businesses/{biz_id}/versions", json=ver_payload)
    assert ver_res.status_code in [200, 201]
    assert ver_res.json()["data"]["version_number"] >= 1
