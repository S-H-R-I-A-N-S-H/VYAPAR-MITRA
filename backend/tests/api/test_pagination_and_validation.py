import uuid
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import get_current_user

client = TestClient(app)
USER_ID = str(uuid.uuid4())


@pytest.fixture
def auth_user():
    def override_get_current_user():
        return {
            "sub": USER_ID,
            "id": USER_ID,
            "email": "p2_test@vyapar.in",
            "role": "authenticated",
        }

    app.dependency_overrides[get_current_user] = override_get_current_user
    yield USER_ID
    app.dependency_overrides.pop(get_current_user, None)


def test_business_pagination_limit_and_offset(auth_user):
    """Verify GET /businesses respects page and page_size query parameters."""
    # Create 3 businesses
    for i in range(3):
        res = client.post(
            "/api/v1/businesses",
            json={
                "name": f"P2 Farm Enterprise {i}",
                "domain": "Agriculture",
                "product_or_service": "Organic Wheat",
            },
        )
        assert res.status_code == 201

    # Request page 1 with page_size 2
    res_p1 = client.get("/api/v1/businesses?page=1&page_size=2")
    assert res_p1.status_code == 200
    p1_data = res_p1.json()["data"]
    assert len(p1_data) <= 2

    # Request invalid page_size (> 100) -> 422
    res_inv = client.get("/api/v1/businesses?page=1&page_size=150")
    assert res_inv.status_code == 422


def test_max_length_validation_enforced(auth_user):
    """Verify input fields exceeding max_length constraints are rejected with 422 (MED-8)."""
    # Business name > 200 chars
    oversized_name = "X" * 205
    res = client.post(
        "/api/v1/businesses",
        json={
            "name": oversized_name,
            "domain": "Agriculture",
            "product_or_service": "Organic Wheat",
        },
    )
    assert res.status_code == 422

    # Evidence claim > 2000 chars
    oversized_claim = "C" * 2050
    res_ev = client.post(
        "/api/v1/evidence/detect-conflicts",
        json=[
            {
                "claim": oversized_claim,
                "source_name": "Test Source",
            }
        ],
    )
    assert res_ev.status_code == 422
