import uuid
from datetime import datetime, timezone
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.security import get_current_user
from app.schemas.evidence import EvidenceItem
from app.services.conflict_detector import ConflictDetector

client = TestClient(app)
MOCK_USER_ID = str(uuid.uuid4())


@pytest.fixture
def auth_user():
    def override_get_current_user():
        return {
            "sub": MOCK_USER_ID,
            "id": MOCK_USER_ID,
            "email": "mappls_test@vyapar.in",
            "role": "authenticated",
        }

    app.dependency_overrides[get_current_user] = override_get_current_user
    yield MOCK_USER_ID
    app.dependency_overrides.pop(get_current_user, None)


def test_locality_competitors_unauthorized():
    response = client.get(
        "/api/v1/locality/competitors",
        params={"category": "Dairy", "query": "Baramati"},
    )
    assert response.status_code == 401


def test_get_locality_competitors_endpoint(auth_user):
    response = client.get(
        "/api/v1/locality/competitors",
        params={"category": "Dairy", "query": "Baramati", "radius_km": 5.0},
    )
    assert response.status_code == 200
    json_data = response.json()
    assert json_data["success"] is True
    data = json_data["data"]
    assert "competitors" in data
    assert len(data["competitors"]) > 0
    assert "location" in data
    assert data["location"]["latitude"] is not None


def test_research_project_competitor_discovery(auth_user):
    # 1. Create a business and location first
    biz_res = client.post(
        "/api/v1/businesses",
        json={
            "name": "Baramati Dairy Hub",
            "domain": "Dairy",
            "product_or_service": "Chilled Bulk Milk",
            "description": "Local collection hub chilling milk for cooperative pickup."
        },
    )
    assert biz_res.status_code == 201
    biz_id = biz_res.json()["data"]["id"]

    loc_res = client.post(
        "/api/v1/locations",
        json={
            "state": "Maharashtra",
            "district": "Pune",
            "town_or_village": "Baramati",
            "latitude": 18.1517,
            "longitude": 74.5772,
        },
    )
    assert loc_res.status_code == 201
    loc_id = loc_res.json()["data"]["id"]

    # 2. Create research project
    create_resp = client.post(
        "/api/v1/research/projects",
        json={
            "business_id": biz_id,
            "location_id": loc_id,
            "research_scope": "local_5km",
        },
    )
    assert create_resp.status_code in [200, 201]
    project_id = create_resp.json()["data"]["id"]

    # 2. Trigger Mappls competitor discovery for this project
    disc_resp = client.post(
        f"/api/v1/research/projects/{project_id}/discover-competitors",
        params={"category": "Dairy", "radius_km": 5.0},
    )
    assert disc_resp.status_code == 200
    disc_data = disc_resp.json()
    assert disc_data["success"] is True
    assert disc_data["data"]["competitor_count"] > 0

    # 3. Verify evidence items include the MAPPLS_POI record
    ev_resp = client.get(f"/api/v1/research/projects/{project_id}/evidence")
    assert ev_resp.status_code == 200
    ev_items = ev_resp.json()["data"]
    mappls_ev = [e for e in ev_items if e["source_type"] == "MAPPLS_POI"]
    assert len(mappls_ev) >= 1
    assert "competitor" in mappls_ev[0]["claim"].lower()


def test_conflict_detector_identifies_competition_contradiction():
    now = datetime.now(timezone.utc)
    evidence_records = [
        EvidenceItem(
            id="ev-sec-comp",
            research_project_id="proj-1",
            claim="Secondary market report predicts low competition and unmet demand in dairy processing.",
            source_name="MSME Regional Report",
            source_type="TRUSTED_WEB",
            confidence_score=0.85,
            created_at=now,
        ),
        EvidenceItem(
            id="ev-prim-comp",
            research_project_id="proj-1",
            claim="3 direct competitors registered locally: Krishna Dairy, Shivkripa Agro, Govind Milk.",
            extracted_value="3",
            source_name="Mappls GeoPOI",
            source_type="MAPPLS_POI",
            confidence_score=0.90,
            created_at=now,
        ),
    ]

    conflicts = ConflictDetector.detect_conflicts(evidence_records)
    assert len(conflicts) >= 1
    comp_conflict = next((c for c in conflicts if c.topic == "Competitor Density"), None)
    assert comp_conflict is not None
    assert comp_conflict.impact_on_confidence == "high_risk"
    assert "active local competitors" in comp_conflict.discrepancy_explanation
