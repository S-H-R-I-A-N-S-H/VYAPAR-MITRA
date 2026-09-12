import pytest
from unittest.mock import MagicMock, patch
from pydantic import BaseModel
from app.adapters.gemini_adapter import GeminiAdapter
from app.core.errors import AIProviderException


class SampleOutputSchema(BaseModel):
    category: str
    confidence: float
    summary: str


@pytest.fixture
def mock_settings():
    with patch("app.adapters.gemini_adapter.settings") as mocked:
        mocked.GEMINI_API_KEY = "test-key-123"
        mocked.GEMINI_MODEL = "gemini-2.0-flash"
        yield mocked


@pytest.fixture
def mock_empty_settings():
    with patch("app.adapters.gemini_adapter.settings") as mocked:
        mocked.GEMINI_API_KEY = ""
        mocked.GEMINI_MODEL = "gemini-2.0-flash"
        yield mocked


@pytest.mark.asyncio
async def test_gemini_adapter_mock_fallback_when_no_api_key(mock_empty_settings):
    adapter = GeminiAdapter()
    assert adapter.is_live is False
    
    response = await adapter.generate_response(
        system_instruction="You are a business mentor.",
        user_prompt="Should I open a grocery store?"
    )
    assert "Mock response from Gemini adapter" in response or "sandbox" in response.lower()


@pytest.mark.asyncio
async def test_gemini_adapter_generate_text_success(mock_settings):
    with patch("google.generativeai.GenerativeModel") as MockModel:
        mock_instance = MagicMock()
        mock_response = MagicMock()
        mock_response.text = "Here is an evidence-based recommendation for your store."
        mock_instance.generate_content.return_value = mock_response
        MockModel.return_value = mock_instance

        adapter = GeminiAdapter()
        assert adapter.is_live is True

        result = await adapter.generate_response(
            system_instruction="You are a business mentor.",
            user_prompt="Evaluate retail grocery store viability in rural market.",
            temperature=0.2
        )

        assert result == "Here is an evidence-based recommendation for your store."
        mock_instance.generate_content.assert_called_once()


@pytest.mark.asyncio
async def test_gemini_adapter_generate_structured_json(mock_settings):
    with patch("google.generativeai.GenerativeModel") as MockModel:
        mock_instance = MagicMock()
        mock_response = MagicMock()
        # Test markdown-wrapped JSON response from Gemini
        mock_response.text = '```json\n{"category": "Retail", "confidence": 0.88, "summary": "Strong local demand."}\n```'
        mock_instance.generate_content.return_value = mock_response
        MockModel.return_value = mock_instance

        adapter = GeminiAdapter()
        parsed = await adapter.generate_structured_output(
            system_instruction="Analyze business domain.",
            user_prompt="Grocery store in village.",
            response_schema=SampleOutputSchema
        )

        assert isinstance(parsed, SampleOutputSchema)
        assert parsed.category == "Retail"
        assert parsed.confidence == 0.88
        assert parsed.summary == "Strong local demand."


@pytest.mark.asyncio
async def test_gemini_adapter_empty_prompt_raises_value_error(mock_settings):
    adapter = GeminiAdapter()
    with pytest.raises(ValueError):
        await adapter.generate_response(
            system_instruction="Test system",
            user_prompt="   "
        )


@pytest.mark.asyncio
async def test_gemini_adapter_retry_on_transient_error(mock_settings):
    with patch("google.generativeai.GenerativeModel") as MockModel:
        mock_instance = MagicMock()
        mock_response = MagicMock()
        mock_response.text = "Recovered response after transient failure."
        
        # First call fails, second succeeds
        mock_instance.generate_content.side_effect = [
            Exception("503 Service Unavailable"),
            mock_response
        ]
        MockModel.return_value = mock_instance

        adapter = GeminiAdapter()
        with patch("asyncio.sleep", return_value=None):
            result = await adapter.generate_response(
                system_instruction="Test instruction",
                user_prompt="Test query",
                max_retries=2
            )

        assert result == "Recovered response after transient failure."
        assert mock_instance.generate_content.call_count == 2


@pytest.mark.asyncio
async def test_gemini_adapter_persistent_failure_raises_ai_provider_exception(mock_settings):
    with patch("google.generativeai.GenerativeModel") as MockModel:
        mock_instance = MagicMock()
        mock_instance.generate_content.side_effect = Exception("429 Resource Exhausted")
        MockModel.return_value = mock_instance

        adapter = GeminiAdapter()
        with patch("asyncio.sleep", return_value=None):
            with pytest.raises(AIProviderException) as exc_info:
                await adapter.generate_response(
                    system_instruction="Test instruction",
                    user_prompt="Test query",
                    max_retries=2
                )
        assert "AI_PROVIDER_ERROR" == exc_info.value.error_code
