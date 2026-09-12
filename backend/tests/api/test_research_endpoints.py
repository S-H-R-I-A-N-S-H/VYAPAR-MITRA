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
            "email": "research_user@vyapar.in",
            "role": "authenticated",
        }

    app.dependency_overrides[get_current_user] = override_get_current_user
    yield MOCK_USER_ID
    app.dependency_overrides.pop(get_current_user, None)


def test_research_endpoints_unauthorized():
    res = client.post("/api/v1/research/projects", json={"business_id": "biz-123", "location_id": "loc-123"})
    assert res.status_code == 401


def test_research_lifecycle_and_survey_pipeline(auth_user):
    # 1. Create a business first
    biz_res = client.post(
        "/api/v1/businesses",
        json={
            "name": "Baramati Dairy Hub",
            "domain": "Dairy",
            "product_or_service": "Chilled Bulk Milk",
            "description": "Local collection hub chilling milk for cooperative pickup."
        }
    )
    biz_id = biz_res.json()["data"]["id"]

    # 2. Create location
    loc_res = client.post(
        "/api/v1/locations",
        json={
            "state": "Maharashtra",
            "district": "Pune",
            "town_or_village": "Baramati"
        }
    )
    loc_id = loc_res.json()["data"]["id"]

    # 3. Create research project
    proj_res = client.post(
        "/api/v1/research/projects",
        json={
            "business_id": biz_id,
            "location_id": loc_id,
            "research_scope": "local_10km"
        }
    )
    assert proj_res.status_code in [200, 201]
    proj_data = proj_res.json()["data"]
    proj_id = proj_data["id"]
    assert proj_data["status"] in ["PLANNED", "ANALYSIS"]

    # 4. Add secondary evidence item
    sec_evidence_payload = {
        "claim": "Government NDDB benchmark purchase price for cow milk is 38 per litre.",
        "extracted_value": "38",
        "unit": "INR/litre",
        "source_name": "NDDB Annual Bulletin",
        "source_type": "GOVERNMENT",
        "confidence_score": 0.95
    }
    sec_ev_res = client.post(f"/api/v1/research/projects/{proj_id}/evidence", json=sec_evidence_payload)
    assert sec_ev_res.status_code in [200, 201]

    # 5. Create a primary field survey
    survey_payload = {
        "research_project_id": proj_id,
        "title": "Local Dairy Farmer Procurement Survey",
        "target_respondent_type": "farmer",
        "questions": [
            {
                "question_text": "What price do you currently receive per litre of cow milk?",
                "question_type": "number"
            },
            {
                "question_text": "Would you sell to a collection point with guaranteed same-day digital weighment?",
                "question_type": "yes_no"
            }
        ]
    }
    survey_res = client.post("/api/v1/surveys", json=survey_payload)
    assert survey_res.status_code in [200, 201]
    survey_id = survey_res.json()["data"]["id"]

    # 6. Submit a field response with divergent pricing to trigger conflict
    response_payload = {
        "survey_id": survey_id,
        "respondent_identifier": "Farmer-01-Suresh",
        "answers": {
            "current_price": 28,  # Discrepancy with 38 benchmark (>20%)
            "switch_intent": "yes"
        },
        "extracted_claim": "Local dairy farmers currently receive only 28 per litre from middlemen.",
        "extracted_value": "28",
        "unit": "INR/litre"
    }
    resp_res = client.post(f"/api/v1/surveys/{survey_id}/responses", json=response_payload)
    assert resp_res.status_code in [200, 201]

    # 7. Check evidence list
    ev_list_res = client.get(f"/api/v1/research/projects/{proj_id}/evidence")
    assert ev_list_res.status_code == 200
    evidence_items = ev_list_res.json()["data"]
    assert len(evidence_items) >= 2  # secondary + primary

    # 8. Check conflicts detected
    conflicts_res = client.get(f"/api/v1/research/projects/{proj_id}/conflicts")
    assert conflicts_res.status_code == 200
    conflicts = conflicts_res.json()["data"]
    assert len(conflicts) >= 1
    assert "Pricing" in conflicts[0]["topic"] or "price" in conflicts[0]["topic"].lower()

    # 9. Check uncertainty report
    unc_res = client.get(f"/api/v1/research/projects/{proj_id}/uncertainty")
    assert unc_res.status_code == 200
    unc_report = unc_res.json()["data"]
    assert unc_report["has_primary_research"] is True
    assert unc_report["has_secondary_research"] is True
    assert unc_report["conflict_count"] >= 1
