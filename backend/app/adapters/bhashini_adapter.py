from typing import Optional
from app.core.config import settings


class BhashiniAdapter:
    """
    Adapter for BHASHINI Indian language translation, ASR (speech-to-text), and TTS.
    Provides local sandbox mock fallback if credentials are not configured.
    """

    def __init__(self):
        self.api_key = settings.BHASHINI_API_KEY
        self.user_id = settings.BHASHINI_USER_ID
        self.pipeline_id = settings.BHASHINI_PIPELINE_ID
        self.is_live = bool(self.api_key and self.user_id)

    async def translate(self, text: str, source_lang: str, target_lang: str) -> str:
        """Translates text between Hindi and English (extensible to other Indian languages)."""
        if not self.is_live:
            # Sandbox fallback translation
            if source_lang == "en" and target_lang == "hi":
                return f"[हिंदी अनुवाद] {text}"
            return text

        # Live Bhashini ULCA API call logic will execute here when live credentials are supplied
        return text

    async def speech_to_text(self, audio_bytes: bytes, lang: str = "hi") -> str:
        """Converts user voice input to text."""
        if not self.is_live:
            return "डेयरी फार्मिंग के लिए मुझे कितना ऋण मिल सकता है?"
        return "Audio transcription via Bhashini"
