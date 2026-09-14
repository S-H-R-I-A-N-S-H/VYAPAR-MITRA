import logging
from typing import Any, Dict, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.adapters.bhashini_adapter import BhashiniAdapter
from app.core.security import get_current_user
from app.schemas.common import APIResponse

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/speech")
bhashini_adapter = BhashiniAdapter()


class TranscribeRequest(BaseModel):
    audio_base64: str = Field(..., min_length=1, description="Base64 encoded audio bytes")
    language: str = Field(default="hi", description="ISO language code (e.g. hi, mr, gu, ta, te)")


class TranscribeResponse(BaseModel):
    transcription: str
    language: str


class SynthesizeRequest(BaseModel):
    text: str = Field(..., min_length=1, description="Text to convert to speech")
    language: str = Field(default="hi", description="ISO language code")
    gender: str = Field(default="female", description="Voice gender: female or male")


class SynthesizeResponse(BaseModel):
    audio_base64: str
    format: str = "wav"
    language: str


class TranslateRequest(BaseModel):
    text: str = Field(..., min_length=1, description="Text to translate")
    source_language: str = Field(default="en")
    target_language: str = Field(default="hi")


class TranslateResponse(BaseModel):
    translated_text: str
    source_language: str
    target_language: str


@router.post(
    "/transcribe",
    response_model=APIResponse[TranscribeResponse],
    summary="Transcribe regional speech audio to text via Bhashini ASR",
)
async def transcribe_speech(
    req: TranscribeRequest,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    cleaned_audio = req.audio_base64.strip()
    if not cleaned_audio:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Audio payload must not be empty.",
        )

    transcription = await bhashini_adapter.speech_to_text(cleaned_audio, lang=req.language)
    if not transcription:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Could not transcribe audio. Ensure audio contains clear speech.",
        )

    return APIResponse(
        success=True,
        data=TranscribeResponse(transcription=transcription, language=req.language),
        message="Audio transcribed successfully.",
    )


@router.post(
    "/synthesize",
    response_model=APIResponse[SynthesizeResponse],
    summary="Synthesize regional language text into speech audio via Bhashini TTS",
)
async def synthesize_speech(
    req: SynthesizeRequest,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    cleaned_text = req.text.strip()
    if not cleaned_text:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Text payload must not be empty.",
        )

    audio_b64 = await bhashini_adapter.text_to_speech(
        cleaned_text, lang=req.language, gender=req.gender
    )

    return APIResponse(
        success=True,
        data=SynthesizeResponse(
            audio_base64=audio_b64,
            format="wav",
            language=req.language,
        ),
        message="Speech synthesized successfully.",
    )


@router.post(
    "/translate",
    response_model=APIResponse[TranslateResponse],
    summary="Translate text across Indian languages via Bhashini NMT",
)
async def translate_text(
    req: TranslateRequest,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    cleaned_text = req.text.strip()
    if not cleaned_text:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Text payload must not be empty.",
        )

    translated = await bhashini_adapter.translate(
        cleaned_text,
        source_lang=req.source_language,
        target_lang=req.target_language,
    )

    return APIResponse(
        success=True,
        data=TranslateResponse(
            translated_text=translated,
            source_language=req.source_language,
            target_language=req.target_language,
        ),
        message="Text translated successfully.",
    )
