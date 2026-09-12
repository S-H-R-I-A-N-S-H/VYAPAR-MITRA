from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field


class LocationCreate(BaseModel):
    state: str
    district: str
    town_or_village: str
    pincode: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class LocationResponse(LocationCreate):
    id: str
    created_at: datetime


class EntrepreneurProfileCreate(BaseModel):
    full_name: str
    preferred_language: str = Field(default="hi", description="hi or en")
    voice_enabled: bool = True
    location: LocationCreate
    available_capital: float = Field(ge=0, description="Available own funds in INR")
    skills: List[str] = Field(default_factory=list)
    interests: List[str] = Field(default_factory=list)
    risk_preference: str = Field(default="moderate", description="conservative, moderate, aggressive")
    
    # Optional consented category for affirmative scheme matching (PMEGP, Stand-Up India, etc.)
    scheme_category: Optional[str] = Field(default="general", description="general, obc, sc, st, woman, minority")
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
    full_name: Optional[str] = None
    preferred_language: Optional[str] = None
    voice_enabled: Optional[bool] = None
    available_capital: Optional[float] = Field(default=None, ge=0)
    skills: Optional[List[str]] = None
    interests: Optional[List[str]] = None
    risk_preference: Optional[str] = None
    scheme_category: Optional[str] = None
    location_id: Optional[str] = None
