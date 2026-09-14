import pytest
import time
from unittest.mock import AsyncMock, MagicMock, patch
from app.adapters.mappls_adapter import MapplsAdapter


@pytest.fixture
def mock_empty_settings():
    with patch("app.adapters.mappls_adapter.settings") as mocked:
        mocked.MAPPLS_CLIENT_ID = ""
        mocked.MAPPLS_CLIENT_SECRET = ""
        yield mocked


@pytest.fixture
def mock_live_settings():
    with patch("app.adapters.mappls_adapter.settings") as mocked:
        mocked.MAPPLS_CLIENT_ID = "test_client_id"
        mocked.MAPPLS_CLIENT_SECRET = "test_client_secret"
        yield mocked


@pytest.mark.asyncio
async def test_mappls_adapter_sandbox_when_no_credentials(mock_empty_settings):
    adapter = MapplsAdapter()
    assert adapter.is_live is False

    results = await adapter.geocode("Baramati")
    assert len(results) > 0
    assert results[0]["district"] == "Pune" or "Baramati" in results[0]["village"]
    assert "latitude" in results[0]
    assert "longitude" in results[0]


@pytest.mark.asyncio
async def test_mappls_adapter_sandbox_find_competitors(mock_empty_settings):
    adapter = MapplsAdapter()
    assert adapter.is_live is False

    competitors = await adapter.find_nearby_competitors(18.5204, 73.8567, category="Dairy", radius_km=5.0)
    assert len(competitors) >= 2
    assert any("Dairy" in c["name"] for c in competitors)
    assert all("distance_km" in c for c in competitors)


@pytest.mark.asyncio
async def test_mappls_adapter_blank_query_returns_empty(mock_empty_settings):
    adapter = MapplsAdapter()
    results = await adapter.geocode("   ")
    assert results == []


@pytest.mark.asyncio
async def test_mappls_adapter_live_token_and_geocode_success(mock_live_settings):
    adapter = MapplsAdapter()
    assert adapter.is_live is True

    # Mock HTTP client responses
    mock_token_resp = MagicMock()
    mock_token_resp.status_code = 200
    mock_token_resp.json.return_value = {
        "access_token": "mock_mappls_jwt_token",
        "token_type": "bearer",
        "expires_in": 3600,
    }

    mock_geocode_resp = MagicMock()
    mock_geocode_resp.status_code = 200
    mock_geocode_resp.json.return_value = {
        "copResults": [
            {
                "latitude": 18.1517,
                "longitude": 74.5772,
                "formattedAddress": "Baramati, Pune, Maharashtra",
                "subDistrict": "Baramati",
                "district": "Pune",
                "state": "Maharashtra",
                "pincode": "413102",
            }
        ]
    }

    with patch("httpx.AsyncClient") as MockClient:
        client_instance = AsyncMock()
        client_instance.__aenter__.return_value = client_instance
        # 1st call: token POST, 2nd call: geocode GET
        client_instance.post.return_value = mock_token_resp
        client_instance.get.return_value = mock_geocode_resp
        MockClient.return_value = client_instance

        results = await adapter.geocode("Baramati")

        assert len(results) == 1
        assert results[0]["district"] == "Pune"
        assert results[0]["latitude"] == 18.1517
        assert results[0]["longitude"] == 74.5772
        assert results[0]["pincode"] == "413102"
        assert adapter._cached_token == "mock_mappls_jwt_token"


@pytest.mark.asyncio
async def test_mappls_adapter_live_nearby_competitors_success(mock_live_settings):
    adapter = MapplsAdapter()
    adapter._cached_token = "valid_cached_token"
    adapter._token_expiry = time.time() + 1800

    mock_nearby_resp = MagicMock()
    mock_nearby_resp.status_code = 200
    mock_nearby_resp.json.return_value = {
        "suggestedLocations": [
            {
                "placeName": "Kisan Dairy Processing Unit",
                "distance": 1500,
                "placeAddress": "Station Road, Baramati",
            },
            {
                "placeName": "Sahyadri Milk Chilling Center",
                "distance": 3200,
                "placeAddress": "MIDC Area, Baramati",
            },
        ]
    }

    with patch("httpx.AsyncClient") as MockClient:
        client_instance = AsyncMock()
        client_instance.__aenter__.return_value = client_instance
        client_instance.get.return_value = mock_nearby_resp
        MockClient.return_value = client_instance

        competitors = await adapter.find_nearby_competitors(18.15, 74.57, category="Dairy")

        assert len(competitors) == 2
        assert competitors[0]["name"] == "Kisan Dairy Processing Unit"
        assert competitors[0]["distance_km"] == 1.5
        assert competitors[1]["distance_km"] == 3.2


@pytest.mark.asyncio
async def test_mappls_adapter_live_network_error_graceful_fallback(mock_live_settings):
    adapter = MapplsAdapter()

    with patch("httpx.AsyncClient") as MockClient:
        client_instance = AsyncMock()
        client_instance.__aenter__.return_value = client_instance
        client_instance.post.side_effect = Exception("Connection timed out")
        MockClient.return_value = client_instance

        # Should log warning and fall back to sandbox data without crashing
        results = await adapter.geocode("Solapur")
        assert len(results) > 0
        assert "Solapur" in results[0]["village"]
