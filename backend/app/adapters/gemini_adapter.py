import asyncio
import json
import logging
import re
from typing import Optional, Type, TypeVar
from pydantic import BaseModel

from app.core.config import settings
from app.core.errors import AIProviderException

logger = logging.getLogger(__name__)

T = TypeVar("T", bound=BaseModel)


class GeminiAdapter:
    """
    Production-grade adapter for Google Gemini Generative AI API (google-genai SDK).
    Uses async-native google.genai.Client with exponential backoff retries,
    structured JSON output extraction, and offline fallback mode.
    """

    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        self.model_name = settings.GEMINI_MODEL
        self._client = None

        if self.api_key and self.api_key.strip():
            try:
                from google import genai  # new google-genai package

                self._client = genai.Client(api_key=self.api_key)
                logger.info(
                    f"[GeminiAdapter] Initialized google-genai client, model={self.model_name}"
                )
            except Exception as e:
                logger.warning(
                    f"[GeminiAdapter] Failed to initialize client: {e}. Falling back to sandbox."
                )
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
        timeout_seconds: float = 20.0,
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

        from google.genai import types as genai_types

        last_exception = None

        for attempt in range(max_retries):
            try:
                response = await asyncio.wait_for(
                    self._client.aio.models.generate_content(
                        model=self.model_name,
                        contents=user_prompt.strip(),
                        config=genai_types.GenerateContentConfig(
                            system_instruction=system_instruction,
                            temperature=temperature,
                            max_output_tokens=2048,
                            automatic_function_calling=genai_types.AutomaticFunctionCallingConfig(disable=True),
                        ),
                    ),
                    timeout=timeout_seconds,
                )
                text = response.text
                if text and text.strip():
                    return text.strip()
                raise ValueError("Empty response received from Gemini API.")
            except Exception as e:
                last_exception = e
                logger.warning(
                    f"[GeminiAdapter] Attempt {attempt + 1}/{max_retries} failed: {e}"
                )
                if attempt < max_retries - 1:
                    backoff = 0.5 * (2 ** attempt)
                    await asyncio.sleep(backoff)

        logger.error(
            f"[GeminiAdapter] Permanently failed after {max_retries} attempts: {last_exception}"
        )
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
            logger.error(
                f"[GeminiAdapter] Failed to parse structured JSON: {clean_json[:200]}. Error: {e}"
            )
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
