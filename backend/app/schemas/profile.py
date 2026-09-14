from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field


class LocationCreate(BaseModel):
    state: str = Field(..., max_length=100)
    district: str = Field(..., max_length=100)
    town_or_village: str = Field(..., max_length=150)
    pincode: Optional[str] = Field(default=None, max_length=20)
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class LocationResponse(LocationCreate):
    id: str
    created_at: datetime


class EntrepreneurProfileCreate(BaseModel):
    full_name: str = Field(..., max_length=200)
    preferred_language: str = Field(default="hi", max_length=20, description="hi or en")
    voice_enabled: bool = True
    location: LocationCreate
    available_capital: float = Field(ge=0, description="Available own funds in INR")
    skills: List[str] = Field(default_factory=list)
    interests: List[str] = Field(default_factory=list)
    risk_preference: str = Field(default="moderate", max_length=50, description="conservative, moderate, aggressive")
    
    # Optional consented category for affirmative scheme matching (PMEGP, Stand-Up India, etc.)
    scheme_category: Optional[str] = Field(default="general", max_length=50, description="general, obc, sc, st, woman, minority")
    consent_recorded: bool = Field(default=False, description="Explicit consent for category use in scheme checks")


class EntrepreneurProfileResponse(BaseModel):
    id: str
    user_id: str
    full_name: str
    preferred_language: str
    voice_enabled: bool
    location_id: Optional[str] = None
    available_capital: float
    skills: List[str]
    interests: List[str]
    risk_preference: str
    scheme_category: Optional[str] = "general"
    created_at: datetime
    updated_at: datetime


class EntrepreneurProfileUpdate(BaseModel):
    full_name: Optional[str] = Field(default=None, max_length=200)
    preferred_language: Optional[str] = Field(default=None, max_length=20)
    voice_enabled: Optional[bool] = None
    available_capital: Optional[float] = Field(default=None, ge=0)
    skills: Optional[List[str]] = None
    interests: Optional[List[str]] = None
    risk_preference: Optional[str] = Field(default=None, max_length=50)
    scheme_category: Optional[str] = Field(default=None, max_length=50)
    location_id: Optional[str] = None

