import base64
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from app.adapters.bhashini_adapter import BhashiniAdapter


@pytest.fixture
def mock_empty_settings():
    with patch("app.adapters.bhashini_adapter.settings") as mocked:
        mocked.BHASHINI_API_KEY = ""
        mocked.BHASHINI_USER_ID = ""
        mocked.BHASHINI_INFERENCE_KEY = ""
        mocked.BHASHINI_PIPELINE_ID = ""
        yield mocked


@pytest.fixture
def mock_live_settings():
    with patch("app.adapters.bhashini_adapter.settings") as mocked:
        mocked.BHASHINI_API_KEY = "test_bhashini_api_key"
        mocked.BHASHINI_USER_ID = "test_bhashini_user_id"
        mocked.BHASHINI_INFERENCE_KEY = ""
        mocked.BHASHINI_PIPELINE_ID = "64392f96daac500b55c543d0"
        yield mocked


@pytest.fixture
def mock_inference_settings():
    with patch("app.adapters.bhashini_adapter.settings") as mocked:
        mocked.BHASHINI_API_KEY = ""
        mocked.BHASHINI_USER_ID = ""
        mocked.BHASHINI_INFERENCE_KEY = "test_inference_key_999"
        mocked.BHASHINI_PIPELINE_ID = "64392f96daac500b55c543d0"
        yield mocked


@pytest.mark.asyncio
async def test_bhashini_sandbox_speech_to_text(mock_empty_settings):
    adapter = BhashiniAdapter()
    assert adapter.is_live is False

    dummy_audio = b"RIFF....WAVEfmt ...."
    transcription = await adapter.speech_to_text(dummy_audio, lang="hi")
    assert len(transcription) > 0
    assert "ऋण" in transcription or "डेयरी" in transcription or "व्यापार" in transcription


@pytest.mark.asyncio
async def test_bhashini_sandbox_text_to_speech(mock_empty_settings):
    adapter = BhashiniAdapter()
    assert adapter.is_live is False

    audio_b64 = await adapter.text_to_speech("नमस्ते, व्यापार मित्र में आपका स्वागत है।", lang="hi")
    assert audio_b64 is not None
    assert len(audio_b64) > 20
    # Verify it decodes to valid bytes
    decoded = base64.b64decode(audio_b64)
    assert len(decoded) > 0


@pytest.mark.asyncio
async def test_bhashini_sandbox_translate(mock_empty_settings):
    adapter = BhashiniAdapter()
    assert adapter.is_live is False

    res = await adapter.translate("Hello entrepreneur", source_lang="en", target_lang="hi")
    assert "हिंदी" in res or "Hello" in res


@pytest.mark.asyncio
async def test_bhashini_empty_input_handling(mock_empty_settings):
    adapter = BhashiniAdapter()
    assert await adapter.speech_to_text(b"") == ""
    assert await adapter.text_to_speech("") == ""
    assert await adapter.translate("", "en", "hi") == ""


@pytest.mark.asyncio
async def test_bhashini_live_speech_to_text_success(mock_live_settings):
    adapter = BhashiniAdapter()
    assert adapter.is_live is True

    # 1. Mock pipeline config response
    mock_config_resp = MagicMock()
    mock_config_resp.status_code = 200
    mock_config_resp.json.return_value = {
        "pipelineResponseConfig": [
            {
                "taskType": "asr",
                "config": [{"serviceId": "ai4bharat/conformer-hi-gpu"}],
            }
        ],
        "pipelineInferenceAPIEndPoint": {
            "endpoint": "https://dhruva-api.bhashini.gov.in/services/inference/pipeline",
            "inferenceApiKey": {"name": "Authorization", "value": "mock_inference_token_123"},
        },
    }

    # 2. Mock compute response
    mock_compute_resp = MagicMock()
    mock_compute_resp.status_code = 200
    mock_compute_resp.json.return_value = {
        "pipelineResponse": [
            {
                "taskType": "asr",
                "output": [{"source": "मुझे आटा चक्की शुरू करने के लिए लोन चाहिए"}],
            }
        ]
    }

    with patch("httpx.AsyncClient") as MockClient:
        client_instance = AsyncMock()
        client_instance.__aenter__.return_value = client_instance
        client_instance.post.side_effect = [mock_config_resp, mock_compute_resp]
        MockClient.return_value = client_instance

        audio_bytes = b"fake_wav_bytes_123"
        result = await adapter.speech_to_text(audio_bytes, lang="hi")

        assert result == "मुझे आटा चक्की शुरू करने के लिए लोन चाहिए"


@pytest.mark.asyncio
async def test_bhashini_live_text_to_speech_success(mock_live_settings):
    adapter = BhashiniAdapter()
    assert adapter.is_live is True

    mock_config_resp = MagicMock()
    mock_config_resp.status_code = 200
    mock_config_resp.json.return_value = {
        "pipelineResponseConfig": [
            {
                "taskType": "tts",
                "config": [{"serviceId": "ai4bharat/indic-tts-hi"}],
            }
        ],
        "pipelineInferenceAPIEndPoint": {
            "endpoint": "https://dhruva-api.bhashini.gov.in/services/inference/pipeline",
            "inferenceApiKey": {"name": "Authorization", "value": "mock_inference_token_123"},
        },
    }

    sample_b64_audio = base64.b64encode(b"RIFF_MOCK_AUDIO_OUTPUT").decode("utf-8")
    mock_compute_resp = MagicMock()
    mock_compute_resp.status_code = 200
    mock_compute_resp.json.return_value = {
        "pipelineResponse": [
            {
                "taskType": "tts",
                "audio": [{"audioContent": sample_b64_audio}],
            }
        ]
    }

    with patch("httpx.AsyncClient") as MockClient:
        client_instance = AsyncMock()
        client_instance.__aenter__.return_value = client_instance
        client_instance.post.side_effect = [mock_config_resp, mock_compute_resp]
        MockClient.return_value = client_instance

        audio_res = await adapter.text_to_speech("व्यापार योजना तैयार है।", lang="hi")
        assert audio_res == sample_b64_audio


@pytest.mark.asyncio
async def test_bhashini_live_failure_falls_back_to_sandbox(mock_live_settings):
    adapter = BhashiniAdapter()

    with patch("httpx.AsyncClient") as MockClient:
        client_instance = AsyncMock()
        client_instance.__aenter__.return_value = client_instance
        client_instance.post.side_effect = Exception("ULCA server connection error")
        MockClient.return_value = client_instance

        # Must degrade gracefully to sandbox output without raising uncaught exception
        transcription = await adapter.speech_to_text(b"some_audio_bytes", lang="hi")
        assert len(transcription) > 0


@pytest.mark.asyncio
async def test_bhashini_direct_inference_speech_to_text(mock_inference_settings):
    adapter = BhashiniAdapter()
    assert adapter.is_live is True
    assert adapter.inference_key == "test_inference_key_999"

    mock_compute_resp = MagicMock()
    mock_compute_resp.status_code = 200
    mock_compute_resp.json.return_value = {
        "pipelineResponse": [
            {
                "taskType": "asr",
                "output": [{"source": "मशीन खरीदने के लिए मुद्रा लोन चाहिए"}],
            }
        ]
    }

    with patch("httpx.AsyncClient") as MockClient:
        client_instance = AsyncMock()
        client_instance.__aenter__.return_value = client_instance
        client_instance.post.return_value = mock_compute_resp
        MockClient.return_value = client_instance

        res = await adapter.speech_to_text(b"mock_audio_bytes", lang="hi")
        assert res == "मशीन खरीदने के लिए मुद्रा लोन चाहिए"

        # Verify it directly posted to Dhruva inference endpoint with Authorization header
        assert client_instance.post.call_count == 1
        call_args = client_instance.post.call_args
        assert call_args[0][0] == adapter.INFERENCE_URL
        assert call_args[1]["headers"]["Authorization"] == "test_inference_key_999"
        assert call_args[1]["json"]["pipelineTasks"][0]["config"]["serviceId"] == adapter.DEFAULT_SERVICE_IDS["asr"]


@pytest.mark.asyncio
async def test_bhashini_direct_inference_translation(mock_inference_settings):
    adapter = BhashiniAdapter()
    assert adapter.is_live is True

    mock_compute_resp = MagicMock()
    mock_compute_resp.status_code = 200
    mock_compute_resp.json.return_value = {
        "pipelineResponse": [
            {
                "taskType": "translation",
                "output": [{"target": "How much loan can I get for dairy farming?"}],
            }
        ]
    }

    with patch("httpx.AsyncClient") as MockClient:
        client_instance = AsyncMock()
        client_instance.__aenter__.return_value = client_instance
        client_instance.post.return_value = mock_compute_resp
        MockClient.return_value = client_instance

        res = await adapter.translate("डेयरी फार्मिंग के लिए कितना लोन मिलेगा?", source_lang="hi", target_lang="en")
        assert res == "How much loan can I get for dairy farming?"

        assert client_instance.post.call_count == 1
        call_args = client_instance.post.call_args
        assert call_args[0][0] == adapter.INFERENCE_URL
        assert call_args[1]["headers"]["Authorization"] == "test_inference_key_999"
        assert call_args[1]["json"]["pipelineTasks"][0]["config"]["serviceId"] == adapter.DEFAULT_SERVICE_IDS["translation"]


@pytest.mark.asyncio
async def test_bhashini_direct_inference_text_to_speech(mock_inference_settings):
    adapter = BhashiniAdapter()
    assert adapter.is_live is True

    mock_audio_b64 = base64.b64encode(b"WAV_DIRECT_INFERENCE_AUDIO").decode("utf-8")
    mock_compute_resp = MagicMock()
    mock_compute_resp.status_code = 200
    mock_compute_resp.json.return_value = {
        "pipelineResponse": [
            {
                "taskType": "tts",
                "audio": [{"audioContent": mock_audio_b64}],
            }
        ]
    }

    with patch("httpx.AsyncClient") as MockClient:
        client_instance = AsyncMock()
        client_instance.__aenter__.return_value = client_instance
        client_instance.post.return_value = mock_compute_resp
        MockClient.return_value = client_instance

        audio_res = await adapter.text_to_speech("आपका आवेदन स्वीकार कर लिया गया है।", lang="hi")
        assert audio_res == mock_audio_b64

        assert client_instance.post.call_count == 1
        call_args = client_instance.post.call_args
        assert call_args[0][0] == adapter.INFERENCE_URL
        assert call_args[1]["headers"]["Authorization"] == "test_inference_key_999"
        assert call_args[1]["json"]["pipelineTasks"][0]["config"]["serviceId"] == adapter.DEFAULT_SERVICE_IDS["tts"]
