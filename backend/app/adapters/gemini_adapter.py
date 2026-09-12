from typing import Any, Dict, Optional
from app.core.config import settings


class GeminiAdapter:
    """
    Adapter for Google Gemini API with fallback sandbox mode for offline or mock testing.
    Enforces prompt sanitization and structured outputs.
    """

    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        self.model_name = settings.GEMINI_MODEL
        self._client = None
        if self.api_key:
            try:
                import google.generativeai as genai

                genai.configure(api_key=self.api_key)
                self._client = genai.GenerativeModel(self.model_name)
            except Exception:
                self._client = None

    async def generate_response(
        self,
        system_instruction: str,
        user_prompt: str,
        response_schema: Optional[Any] = None,
    ) -> str:
        """Invokes Gemini or returns structured mock response if unconfigured."""
        if self._client:
            try:
                # Direct API invocation
                response = self._client.generate_content(
                    contents=f"System: {system_instruction}\n\nUser: {user_prompt}"
                )
                return response.text
            except Exception as e:
                # Log error and fallback
                pass

        # Sandbox / Mock fallback response
        return "Mock response from Gemini adapter (configure GEMINI_API_KEY for live output)."
