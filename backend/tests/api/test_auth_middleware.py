import time
import pytest
from jose import jwt
from fastapi import FastAPI, Depends
from fastapi.testclient import TestClient

from app.core.config import settings
from app.core.errors import UnauthorizedAccessException
from app.core.security import get_current_user_id, get_current_user, AuthenticatedUser


# Create an isolated test app with protected endpoints
test_app = FastAPI()


@test_app.get("/protected/user-id")
async def protected_user_id_endpoint(user_id: str = Depends(get_current_user_id)):
    return {"user_id": user_id}


@test_app.get("/protected/user")
async def protected_user_endpoint(user: AuthenticatedUser = Depends(get_current_user)):
    return {"user_id": user.user_id, "email": user.email, "role": user.role}


@pytest.fixture
def auth_client():
    return TestClient(test_app)


def create_token(payload_updates=None, secret=None):
    """Helper to generate HS256 tokens for testing."""
    secret = secret or settings.SUPABASE_JWT_SECRET
    payload = {
        "sub": "test-user-uuid-12345",
        "email": "entrepreneur@vyaparmitra.org",
        "role": "authenticated",
        "aud": "authenticated",
        "exp": int(time.time()) + 3600,
        "iat": int(time.time()),
    }
    if payload_updates:
        payload.update(payload_updates)
    return jwt.encode(payload, secret, algorithm="HS256")


def test_auth_valid_jwt(auth_client):
    """Verify valid Supabase JWT successfully authenticates and returns user ID."""
    token = create_token()
    response = auth_client.get(
        "/protected/user-id",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    assert response.json()["user_id"] == "test-user-uuid-12345"


def test_auth_get_current_user(auth_client):
    """Verify get_current_user returns typed AuthenticatedUser model."""
    token = create_token({"email": "rural_maker@bihar.org", "role": "authenticated"})
    response = auth_client.get(
        "/protected/user",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["user_id"] == "test-user-uuid-12345"
    assert data["email"] == "rural_maker@bihar.org"
    assert data["role"] == "authenticated"


def test_auth_expired_jwt(auth_client):
    """Verify expired token is rejected with explicit expiration message."""
    token = create_token({"exp": int(time.time()) - 100})
    response = auth_client.get(
        "/protected/user-id",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 401
    assert "expired" in response.json()["detail"].lower()


def test_auth_tampered_jwt(auth_client):
    """Verify token signed with wrong secret is rejected."""
    wrong_secret = "invalid_secret_key_12345678901234567890"
    token = create_token(secret=wrong_secret)
    response = auth_client.get(
        "/protected/user-id",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 401


def test_auth_missing_header(auth_client):
    """Verify request with no Authorization header is rejected."""
    response = auth_client.get("/protected/user-id")
    assert response.status_code == 401
    assert "missing" in response.json()["detail"].lower()


def test_auth_malformed_header(auth_client):
    """Verify request with invalid header format is rejected."""
    response = auth_client.get(
        "/protected/user-id",
        headers={"Authorization": "Basic some_token"},
    )
    assert response.status_code == 401
    assert "bearer" in response.json()["detail"].lower()


def test_auth_mock_token_dev_vs_prod(auth_client, monkeypatch):
    """Verify mock token works in development mode but fails in production mode."""
    # Dev mode:
    monkeypatch.setattr(settings, "ENVIRONMENT", "development")
    response = auth_client.get(
        "/protected/user-id",
        headers={"Authorization": "Bearer mock-user-local-123"},
    )
    assert response.status_code == 200
    assert response.json()["user_id"] == "local-123"

    # Production mode: mock tokens MUST be rejected
    monkeypatch.setattr(settings, "ENVIRONMENT", "production")
    response_prod = auth_client.get(
        "/protected/user-id",
        headers={"Authorization": "Bearer mock-user-local-123"},
    )
    assert response_prod.status_code == 401


def test_auth_dev_allow_anonymous(auth_client, monkeypatch):
    """Verify DEV_ALLOW_ANONYMOUS permits anonymous / fallback requests in development but not in production."""
    # Dev mode with DEV_ALLOW_ANONYMOUS = True:
    monkeypatch.setattr(settings, "ENVIRONMENT", "development")
    monkeypatch.setattr(settings, "DEV_ALLOW_ANONYMOUS", True)

    # 1. No header
    res_no_header = auth_client.get("/protected/user-id")
    assert res_no_header.status_code == 200
    assert res_no_header.json()["user_id"] == "dev-001"

    # 2. Malformed / expired token in dev mode
    res_invalid_header = auth_client.get(
        "/protected/user-id",
        headers={"Authorization": "Bearer invalid_or_expired_jwt"},
    )
    assert res_invalid_header.status_code == 200
    assert res_invalid_header.json()["user_id"] == "dev-001"

    # Production mode with DEV_ALLOW_ANONYMOUS = True (should strictly reject):
    monkeypatch.setattr(settings, "ENVIRONMENT", "production")
    res_prod = auth_client.get("/protected/user-id")
    assert res_prod.status_code == 401

