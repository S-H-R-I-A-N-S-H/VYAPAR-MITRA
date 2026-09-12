import asyncio
import json
import logging
import re
from typing import Any, Optional, Type, TypeVar
from pydantic import BaseModel

from app.core.config import settings
from app.core.errors import AIProviderException

logger = logging.getLogger(__name__)

T = TypeVar("T", bound=BaseModel)


class GeminiAdapter:
    """
    Production-grade adapter for Google Gemini Generative AI API with resilience,
    exponential backoff retries, structured JSON output extraction, and offline fallback mode.
    """

    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        self.model_name = settings.GEMINI_MODEL
        self._client = None

        if self.api_key and self.api_key.strip():
            try:
                import google.generativeai as genai

                genai.configure(api_key=self.api_key)
                self._client = genai.GenerativeModel(self.model_name)
            except Exception as e:
                logger.warning(f"Failed to initialize live Gemini client: {e}. Falling back to sandbox.")
                self._client = None

    @property
    def is_live(self) -> bool:
        """Returns True if live Gemini API client is initialized with valid configuration."""
        return self._client is not None

    async def generate_response(
        self,
        system_instruction: str,
        user_prompt: str,
        temperature: float = 0.2,
        max_retries: int = 3,
        timeout_seconds: float = 15.0,
    ) -> str:
        """
        Executes a Gemini prompt with retry resilience, timeout handling, and offline fallback.
        Raises ValueError on empty prompts.
        Raises AIProviderException on persistent API failures.
        """
        if not user_prompt or not user_prompt.strip():
            raise ValueError("user_prompt must not be empty or whitespace.")

        if not self.is_live:
            return "Mock response from Gemini adapter (configure GEMINI_API_KEY for live output)."

        combined_prompt = f"System: {system_instruction}\n\nUser: {user_prompt.strip()}"
        last_exception = None

        for attempt in range(max_retries):
            try:
                # Wrap synchronous generate_content in asyncio executor with timeout
                loop = asyncio.get_running_loop()
                response = await asyncio.wait_for(
                    loop.run_in_executor(
                        None,
                        lambda: self._client.generate_content(
                            contents=combined_prompt,
                            generation_config={"temperature": temperature} if hasattr(self._client, "generate_content") else None
                        )
                    ),
                    timeout=timeout_seconds,
                )
                if response and hasattr(response, "text") and response.text:
                    return response.text.strip()
                raise ValueError("Empty response received from Gemini API.")
            except Exception as e:
                last_exception = e
                logger.warning(
                    f"Gemini API attempt {attempt + 1}/{max_retries} failed with error: {e}"
                )
                if attempt < max_retries - 1:
                    backoff = 0.5 * (2 ** attempt)
                    await asyncio.sleep(backoff)

        logger.error(f"Gemini API failed permanently after {max_retries} attempts: {last_exception}")
        raise AIProviderException(
            detail=f"Gemini API service invocation failed: {str(last_exception)}",
            error_code="AI_PROVIDER_ERROR",
            extra={"attempts": max_retries, "error": str(last_exception)},
        )

    async def generate_structured_output(
        self,
        system_instruction: str,
        user_prompt: str,
        response_schema: Type[T],
        temperature: float = 0.1,
        max_retries: int = 3,
    ) -> T:
        """
        Forces Gemini to return JSON conforming to the given Pydantic schema,
        strips markdown fences, parses and validates the structured model.
        """
        schema_json = json.dumps(response_schema.model_json_schema(), indent=2)
        augmented_system = (
            f"{system_instruction}\n\n"
            f"CRITICAL: You MUST respond ONLY with valid JSON conforming to this JSON Schema. "
            f"Do not include any conversational preamble or postscript.\n"
            f"JSON Schema:\n{schema_json}"
        )

        raw_text = await self.generate_response(
            system_instruction=augmented_system,
            user_prompt=user_prompt,
            temperature=temperature,
            max_retries=max_retries,
        )

        clean_json = self._extract_json(raw_text)
        try:
            return response_schema.model_validate_json(clean_json)
        except Exception as e:
            logger.error(f"Failed to parse structured JSON from model: {clean_json}. Error: {e}")
            raise AIProviderException(
                detail=f"AI output failed schema validation: {str(e)}",
                error_code="AI_SCHEMA_VALIDATION_ERROR",
                extra={"raw_output": raw_text, "validation_error": str(e)},
            )

    @staticmethod
    def _extract_json(text: str) -> str:
        """Strips markdown code blocks, backticks, or trailing commentary to isolate valid JSON."""
        trimmed = text.strip()
        # Look for ```json ... ``` or ``` ... ```
        match = re.search(r"```(?:json)?\s*([\s\S]*?)\s*```", trimmed)
        if match:
            return match.group(1).strip()
        # Check if text already starts with { or [
        start_brace = trimmed.find("{")
        end_brace = trimmed.rfind("}")
        if start_brace != -1 and end_brace != -1 and end_brace > start_brace:
            return trimmed[start_brace : end_brace + 1]
        return trimmed
