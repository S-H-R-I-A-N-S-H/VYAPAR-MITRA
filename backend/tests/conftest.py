import pytest
from fastapi.testclient import TestClient
from app.main import app


from app.core.config import settings


TEST_JWT_SECRET = "ci-test-supabase-jwt-secret-minimum-32-chars-long"


@pytest.fixture(autouse=True)
def enforce_strict_auth_in_tests():
    """Ensures test runs default to strict authentication and hermetic test secrets."""
    original_allow_anon = settings.DEV_ALLOW_ANONYMOUS
    original_jwt_secret = settings.SUPABASE_JWT_SECRET

    settings.DEV_ALLOW_ANONYMOUS = False
    if not settings.SUPABASE_JWT_SECRET:
        settings.SUPABASE_JWT_SECRET = TEST_JWT_SECRET

    yield

    settings.DEV_ALLOW_ANONYMOUS = original_allow_anon
    settings.SUPABASE_JWT_SECRET = original_jwt_secret


@pytest.fixture
def client():
    """Test client fixture for API requests."""
    return TestClient(app)
