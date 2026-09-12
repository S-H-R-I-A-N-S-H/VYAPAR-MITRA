import uuid
import pytest
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, patch
from app.main import app
from app.core.security import get_current_user
from app.services.prompt_service import InterviewTurnResponse, ExtractedFactor


client = TestClient(app)
MOCK_USER_ID = str(uuid.uuid4())


@pytest.fixture
def auth_user():
    def override_get_current_user():
        return {
            "sub": MOCK_USER_ID,
            "email": "interview_user@vyapar.in",
            "role": "authenticated",
        }

    app.dependency_overrides[get_current_user] = override_get_current_user
    yield MOCK_USER_ID
    app.dependency_overrides.pop(get_current_user, None)


def test_interview_unauthorized():
    res = client.post("/api/v1/interviews", json={"language": "hi"})
    assert res.status_code == 401


def test_create_and_run_interview_session(auth_user):
    # 1. Start interview
    create_res = client.post("/api/v1/interviews", json={"language": "hi"})
    assert create_res.status_code in [200, 201]
    create_data = create_res.json()["data"]
    session_id = create_data["id"]
    assert create_data["status"] == "ACTIVE"
    assert create_data["language"] == "hi"

    # 2. Send message
    msg_payload = {
        "content": "Namaste, I have 3 years experience in dairy farming and have 1 lakh rupees capital."
    }
    msg_res = client.post(f"/api/v1/interviews/{session_id}/messages", json=msg_payload)
    assert msg_res.status_code == 200
    turn_data = msg_res.json()["data"]
    assert "reply" in turn_data
    assert len(turn_data["reply"]) > 0
    assert "extracted_factors" in turn_data

    # 3. Get session with history
    get_res = client.get(f"/api/v1/interviews/{session_id}")
    assert get_res.status_code == 200
    session_data = get_res.json()["data"]
    assert len(session_data["messages"]) >= 2  # user message + assistant reply

    # 4. Complete session
    complete_res = client.post(f"/api/v1/interviews/{session_id}/complete")
    assert complete_res.status_code == 200
    assert complete_res.json()["data"]["status"] == "COMPLETED"


def test_send_empty_message_validation_error(auth_user):
    create_res = client.post("/api/v1/interviews", json={"language": "en"})
    session_id = create_res.json()["data"]["id"]

    res = client.post(f"/api/v1/interviews/{session_id}/messages", json={"content": "   "})
    assert res.status_code == 422
