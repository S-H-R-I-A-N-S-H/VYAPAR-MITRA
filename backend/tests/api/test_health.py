from unittest.mock import patch
from app.schemas.common import HealthStatus


def test_health_check_basic(client):
    """Verify health endpoint responds with success status and metadata."""
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"]["status"] in ("ok", "degraded")
    assert "database" in data["data"]


def test_health_check_connected_db(client):
    """Verify health endpoint returns connected status when database is operational."""
    with patch("app.adapters.supabase_adapter.supabase_adapter.check_connection") as mock_check:
        mock_check.return_value = {"status": "connected", "latency_ms": 15.2}
        response = client.get("/api/v1/health")
        assert response.status_code == 200
        data = response.json()
        assert data["data"]["status"] == "ok"
        assert data["data"]["database"]["status"] == "connected"
        assert data["data"]["database"]["latency_ms"] == 15.2


def test_health_check_database_failure_graceful(client):
    """Verify health endpoint does not crash and marks degraded status if database is down."""
    with patch("app.adapters.supabase_adapter.supabase_adapter.check_connection") as mock_check:
        mock_check.return_value = {
            "status": "disconnected",
            "latency_ms": None,
            "error": "Connection timed out",
        }
        response = client.get("/api/v1/health")
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["data"]["status"] == "degraded"
        assert data["data"]["database"]["status"] == "disconnected"
        assert "Connection timed out" in data["data"]["database"]["error"]
