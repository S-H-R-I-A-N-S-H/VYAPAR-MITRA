import base64
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
            "id": MOCK_USER_ID,
            "email": "speech_test@vyapar.in",
            "role": "authenticated",
        }

    app.dependency_overrides[get_current_user] = override_get_current_user
    yield MOCK_USER_ID
    app.dependency_overrides.pop(get_current_user, None)


def test_speech_endpoints_unauthorized():
    res = client.post("/api/v1/speech/transcribe", json={"audio_base64": "fake"})
    assert res.status_code == 401


def test_speech_transcribe_endpoint(auth_user):
    sample_b64 = base64.b64encode(b"RIFF_FAKE_AUDIO_BYTES").decode("utf-8")
    res = client.post(
        "/api/v1/speech/transcribe",
        json={"audio_base64": sample_b64, "language": "hi"},
    )
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is True
    assert "transcription" in data["data"]
    assert len(data["data"]["transcription"]) > 0


def test_speech_synthesize_endpoint(auth_user):
    res = client.post(
        "/api/v1/speech/synthesize",
        json={"text": "व्यापार मित्र में आपका स्वागत है।", "language": "hi"},
    )
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is True
    assert "audio_base64" in data["data"]
    assert len(data["data"]["audio_base64"]) > 0


def test_speech_translate_endpoint(auth_user):
    res = client.post(
        "/api/v1/speech/translate",
        json={"text": "Welcome", "source_language": "en", "target_language": "hi"},
    )
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is True
    assert "translated_text" in data["data"]


def test_conversational_voice_turn_lifecycle(auth_user):
    # 1. Start interview session
    sess_res = client.post(
        "/api/v1/interviews",
        json={"language": "hi"},
    )
    assert sess_res.status_code in [200, 201]
    session_id = sess_res.json()["data"]["id"]

    # 2. Send 2-way voice message
    sample_b64 = base64.b64encode(b"RIFF_SAMPLE_MIC_INPUT").decode("utf-8")
    voice_res = client.post(
        f"/api/v1/interviews/{session_id}/voice",
        json={"audio_base64": sample_b64, "language": "hi"},
    )
    assert voice_res.status_code == 200
    v_data = voice_res.json()
    assert v_data["success"] is True
    data = v_data["data"]
    assert "transcribed_text" in data
    assert len(data["transcribed_text"]) > 0
    assert "reply" in data
    assert len(data["reply"]) > 0
    assert "audio_response_base64" in data
    assert len(data["audio_response_base64"]) > 0
    assert "extracted_factors" in data


def test_conversational_voice_turn_invalid_session(auth_user):
    sample_b64 = base64.b64encode(b"RIFF_SAMPLE_MIC_INPUT").decode("utf-8")
    voice_res = client.post(
        "/api/v1/interviews/non-existent-session-id/voice",
        json={"audio_base64": sample_b64, "language": "hi"},
    )
    assert voice_res.status_code == 404
