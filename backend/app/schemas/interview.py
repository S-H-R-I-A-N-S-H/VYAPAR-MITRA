from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field, field_validator


class InterviewSessionCreate(BaseModel):
    language: str = Field(default="hi", max_length=20, description="ISO language code, e.g. hi, en, mr, gu")
    business_id: Optional[str] = None


class InterviewMessageInput(BaseModel):
    content: str = Field(..., min_length=1, max_length=5000, description="Entrepreneur message")
    language: Optional[str] = Field(default=None, max_length=20)

    @field_validator("content")
    @classmethod
    def validate_non_empty(cls, v: str) -> str:
        cleaned = v.strip()
        if not cleaned:
            raise ValueError("Message content must not be blank or whitespace only.")
        return cleaned


class InterviewMessageItem(BaseModel):
    id: str
    role: str
    content: str
    created_at: datetime


class InterviewSessionResponse(BaseModel):
    id: str
    entrepreneur_id: str
    business_id: Optional[str] = None
    status: str
    language: str
    started_at: datetime
    completed_at: Optional[datetime] = None
    messages: List[InterviewMessageItem] = Field(default_factory=list)


class VoiceTurnInput(BaseModel):
    audio_base64: str = Field(..., min_length=1, description="Base64 encoded audio bytes from mobile microphone")
    language: Optional[str] = Field(default=None, max_length=20)


class VoiceTurnResponse(BaseModel):
    transcribed_text: str
    reply: str
    next_question: Optional[str] = None
    language: str
    audio_response_base64: str
    extracted_factors: List[Any] = Field(default_factory=list)
    is_complete: bool = False
