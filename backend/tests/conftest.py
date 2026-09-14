import pytest
from fastapi.testclient import TestClient
from app.main import app


from app.core.config import settings


@pytest.fixture(autouse=True)
def enforce_strict_auth_in_tests():
    """Ensures test runs default to strict authentication."""
    original = settings.DEV_ALLOW_ANONYMOUS
    settings.DEV_ALLOW_ANONYMOUS = False
    yield
    settings.DEV_ALLOW_ANONYMOUS = original


@pytest.fixture
def client():
    """Test client fixture for API requests."""
    return TestClient(app)
