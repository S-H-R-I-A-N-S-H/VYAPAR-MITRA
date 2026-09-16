import asyncio
import json
import logging
import re
import time
from typing import Any, Dict, List, Optional, Type, TypeVar
from pydantic import BaseModel

from app.core.config import settings
from app.core.errors import AIProviderException

logger = logging.getLogger(__name__)

T = TypeVar("T", bound=BaseModel)


class GeminiAdapter:
    """
    Production-grade adapter for Google Gemini Generative AI API (google-genai SDK).
    Uses async-native google.genai.Client with multi-model cascade resilience,
    quota/rate-limit circuit-breaking cooldown, structured JSON output extraction,
    and offline fallback mode.
    """

    def __init__(self, cooldown_seconds: float = 1800.0):
        self.api_key = settings.GEMINI_API_KEY
        self.model_name = settings.GEMINI_MODEL
        self.cooldown_seconds = cooldown_seconds
        self._model_cooldowns: Dict[str, float] = {}
        self._client = None

        if self.api_key and self.api_key.strip():
            try:
                from google import genai  # new google-genai package

                self._client = genai.Client(api_key=self.api_key)
                logger.info(
                    f"[GeminiAdapter] Initialized google-genai client, primary model={self.model_name}"
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

    def get_candidate_models(self) -> List[str]:
        """Returns the ordered list of candidate models (primary first, then fallbacks)."""
        candidates = [self.model_name]
        fallback_str = getattr(settings, "GEMINI_FALLBACK_MODELS", "") or ""
        for m in fallback_str.split(","):
            clean = m.strip()
            if clean and clean not in candidates:
                candidates.append(clean)
        return candidates

    def get_active_models(self) -> List[str]:
        """
        Returns active candidate models in priority order,
        filtering out models that are currently on circuit-breaker cooldown.
        If all models are on cooldown, returns all candidate models to prevent starvation.
        """
        candidates = self.get_candidate_models()
        now = time.monotonic()
        active = [m for m in candidates if self._model_cooldowns.get(m, 0.0) <= now]
        return active if active else candidates

    @staticmethod
    def _is_immediate_cascade_error(exc: Exception) -> bool:
        """Determines if an exception is permanent quota exhaustion or decommissioned model requiring immediate cascade."""
        err_str = str(exc).lower()
        return (
            "429" in err_str
            or "resource_exhausted" in err_str
            or "quota exceeded" in err_str
            or "404" in err_str
            or "not_found" in err_str
            or "no longer available" in err_str
        )

    async def generate_response(
        self,
        system_instruction: str,
        user_prompt: str,
        temperature: float = 0.2,
        max_retries: int = 2,
        timeout_seconds: float = 20.0,
    ) -> str:
        """
        Executes a Gemini prompt with multi-model cascade, retry resilience,
        timeout handling, and offline fallback.
        Raises ValueError on empty prompts.
        Raises AIProviderException on persistent API failures across all models.
        """
        if not user_prompt or not user_prompt.strip():
            raise ValueError("user_prompt must not be empty or whitespace.")

        if not self.is_live:
            return "Mock response from Gemini adapter (configure GEMINI_API_KEY for live output)."

        from google.genai import types as genai_types

        models_to_try = self.get_active_models()
        last_exception = None

        for model in models_to_try:
            for attempt in range(max_retries):
                try:
                    response = await asyncio.wait_for(
                        self._client.aio.models.generate_content(
                            model=model,
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
                    raise ValueError(f"Empty response received from Gemini model '{model}'.")
                except Exception as e:
                    last_exception = e
                    if self._is_immediate_cascade_error(e):
                        logger.warning(
                            f"[GeminiAdapter] Model '{model}' hit quota exhaustion: {e}. "
                            f"Placing '{model}' on {self.cooldown_seconds}s cooldown and cascading immediately to next model."
                        )
                        self._model_cooldowns[model] = time.monotonic() + self.cooldown_seconds
                        break  # Break retry loop for this model, cascade to next candidate immediately

                    logger.warning(
                        f"[GeminiAdapter] Attempt {attempt + 1}/{max_retries} for model '{model}' failed: {e}"
                    )
                    if attempt < max_retries - 1:
                        backoff = 0.5 * (2 ** attempt)
                        await asyncio.sleep(backoff)
                    else:
                        self._model_cooldowns[model] = time.monotonic() + self.cooldown_seconds

        logger.error(
            f"[GeminiAdapter] Permanently failed across models {models_to_try}: {last_exception}"
        )
        raise AIProviderException(
            detail=f"Gemini API service invocation failed: {str(last_exception)}",
            error_code="AI_PROVIDER_ERROR",
            extra={"models_tried": models_to_try, "error": str(last_exception)},
        )

    async def generate_structured_output(
        self,
        system_instruction: str,
        user_prompt: str,
        response_schema: Type[T],
        temperature: float = 0.1,
        max_retries: int = 2,
    ) -> T:
        """
        Forces Gemini to return JSON conforming to the given Pydantic schema,
        strips markdown fences, parses and validates the structured model.
        Cascades automatically across available models via generate_response.
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

    async def generate_with_search_grounding(
        self,
        system_instruction: str,
        user_prompt: str,
        timeout_seconds: float = 30.0,
    ) -> Dict[str, Any]:
        """
        Executes a prompt with Google Search Grounding to research real-time Indian market data.
        Cascades across available models if quota is exhausted.
        Returns a dict with:
        - "text": string synthesis
        - "sources": list of dicts {"title": str, "url": str}
        - "grounded": bool
        """
        if not self.is_live:
            return {"text": "", "sources": [], "grounded": False}

        from google.genai import types as genai_types

        models_to_try = self.get_active_models()
        last_exception = None

        for model in models_to_try:
            try:
                cfg = genai_types.GenerateContentConfig(
                    system_instruction=system_instruction,
                    temperature=0.2,
                    tools=[genai_types.Tool(google_search=genai_types.GoogleSearch())],
                )
                response = await asyncio.wait_for(
                    self._client.aio.models.generate_content(
                        model=model,
                        contents=user_prompt.strip(),
                        config=cfg,
                    ),
                    timeout=timeout_seconds,
                )

                text = response.text or ""
                sources = []
                grounded = False

                if response.candidates and response.candidates[0].grounding_metadata:
                    grounded = True
                    gm = response.candidates[0].grounding_metadata
                    if hasattr(gm, "grounding_chunks") and gm.grounding_chunks:
                        for chunk in gm.grounding_chunks:
                            if hasattr(chunk, "web") and chunk.web:
                                sources.append({
                                    "title": getattr(chunk.web, "title", "") or "Web Source",
                                    "url": getattr(chunk.web, "uri", "") or "",
                                })

                return {"text": text.strip(), "sources": sources, "grounded": grounded}
            except Exception as e:
                last_exception = e
                if self._is_immediate_cascade_error(e):
                    logger.warning(
                        f"[GeminiAdapter] Search grounding with model '{model}' hit quota error: {e}. "
                        f"Placing on cooldown and cascading..."
                    )
                    self._model_cooldowns[model] = time.monotonic() + self.cooldown_seconds
                    continue
                logger.warning(f"[GeminiAdapter] Search grounding error on '{model}': {e}")

        logger.warning(
            f"[GeminiAdapter] Search grounding failed or quota exhausted across models: {last_exception}"
        )
        return {"text": "", "sources": [], "grounded": False, "error": str(last_exception)}

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
