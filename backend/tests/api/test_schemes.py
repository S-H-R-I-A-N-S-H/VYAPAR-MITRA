from app.adapters.supabase_adapter import supabase_adapter


def test_list_schemes_endpoint(client):
    """Verify GET /api/v1/schemes/ returns all active government schemes from database."""
    response = client.get("/api/v1/schemes/")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert len(data["data"]) >= 5
    scheme_codes = [s["scheme_code"] for s in data["data"]]
    assert "PMEGP" in scheme_codes
    assert "MUDRA_SHISHU" in scheme_codes
    assert "STANDUP_INDIA" in scheme_codes


def test_match_schemes_endpoint(client):
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
