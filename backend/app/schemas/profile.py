from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class LocationCreate(BaseModel):
    state: str = Field(default="Madhya Pradesh")
    district: str = Field(default="Indore")
    town_or_village: str = Field(default="Sanwer")
    pincode: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    rural_or_urban: str = Field(default="rural", description="rural or urban")


class LocationResponse(LocationCreate):
    id: str
    created_at: datetime


class EntrepreneurProfileCreate(BaseModel):
    full_name: str
    preferred_language: str = Field(default="hi", description="hi, mr, en, etc.")
    voice_enabled: bool = True
    location: Optional[LocationCreate] = None
    available_capital: float = Field(default=0.0, ge=0, description="Available own funds in INR")
    skills: List[str] = Field(default_factory=list)
    interests: List[str] = Field(default_factory=list)
    risk_preference: str = Field(default="moderate", description="conservative, moderate, aggressive")
    
    # Demographics & Education
    age: Optional[int] = Field(default=28, ge=18, le=100)
    gender: Optional[str] = Field(default="male", description="male, female, other")
    education: Optional[str] = Field(default="10th_pass", description="below_8th, 8th_pass, 10th_pass, 12th_pass, graduate, postgraduate")
    rural_or_urban: Optional[str] = Field(default="rural", description="rural or urban")
    occupation: Optional[str] = Field(default="Micro-entrepreneur")
    experience_years: Optional[float] = Field(default=2.0, ge=0)
    annual_income: Optional[float] = Field(default=120000.0, ge=0)
    
    # Business attributes (if provided during setup)
    business_name: Optional[str] = Field(default="My Enterprise")
    business_idea: Optional[str] = Field(default="Cold-Press Oil Mill")
    business_activity: Optional[str] = Field(default="Food Processing")
    business_type: Optional[str] = Field(default="manufacturing", description="manufacturing, service, trading")
    business_status: Optional[str] = Field(default="new", description="new, existing, expansion")
    sector: Optional[str] = Field(default="Agri-Processing")
    years_in_business: Optional[float] = Field(default=0.0, ge=0)
    annual_turnover: Optional[float] = Field(default=0.0, ge=0)
    number_of_employees: Optional[int] = Field(default=1, ge=0)
    is_greenfield: Optional[bool] = Field(default=True)

    # Financial requirements
    total_project_cost: Optional[float] = Field(default=250000.0, ge=0)
    own_capital: Optional[float] = Field(default=50000.0, ge=0)
    loan_required: Optional[float] = Field(default=200000.0, ge=0)
    existing_loans: Optional[bool] = Field(default=False)
    existing_loan_amount: Optional[float] = Field(default=0.0, ge=0)
    monthly_emi: Optional[float] = Field(default=0.0, ge=0)
    working_capital_requirement: Optional[float] = Field(default=50000.0, ge=0)
    machinery_equipment_cost: Optional[float] = Field(default=150000.0, ge=0)

    # Government benefit history
    previous_government_subsidy: Optional[bool] = Field(default=False)
    previous_government_loan: Optional[bool] = Field(default=False)
    previously_used_schemes: Optional[List[str]] = Field(default_factory=list)

    # Consented sensitive affirmative attributes
    scheme_category: Optional[str] = Field(default="general", description="general, obc, sc, st, woman, minority, ph, ex_servicemen")
    consent_recorded: bool = Field(default=False, description="Explicit consent for affirmative scheme matching")
    is_woman_entrepreneur: Optional[bool] = Field(default=False)
    disability_category: Optional[str] = None
    minority_category: Optional[str] = None
    ex_serviceman_status: Optional[bool] = Field(default=False)


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
    
    # Extended fields
    age: Optional[int] = 28
    gender: Optional[str] = "male"
    education: Optional[str] = "10th_pass"
    rural_or_urban: Optional[str] = "rural"
    occupation: Optional[str] = "Micro-entrepreneur"
    experience_years: Optional[float] = 2.0
    annual_income: Optional[float] = 120000.0
    previous_government_subsidy: Optional[bool] = False
    previous_government_loan: Optional[bool] = False
    previously_used_schemes: Optional[List[str]] = []
    
    # Business snapshot
    business_id: Optional[str] = None
    business_name: Optional[str] = None
    business_activity: Optional[str] = None
    business_type: Optional[str] = "manufacturing"
    business_status: Optional[str] = "new"
    sector: Optional[str] = None
    total_project_cost: Optional[float] = 250000.0
    own_capital: Optional[float] = 50000.0
    loan_required: Optional[float] = 200000.0
    
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
    
    age: Optional[int] = None
    gender: Optional[str] = None
    education: Optional[str] = None
    rural_or_urban: Optional[str] = None
    occupation: Optional[str] = None
    experience_years: Optional[float] = None
    annual_income: Optional[float] = None
    previous_government_subsidy: Optional[bool] = None
    previous_government_loan: Optional[bool] = None
    previously_used_schemes: Optional[List[str]] = None
    
    business_name: Optional[str] = None
    business_activity: Optional[str] = None
    business_type: Optional[str] = None
    business_status: Optional[str] = None
    sector: Optional[str] = None
    total_project_cost: Optional[float] = None
    own_capital: Optional[float] = None
    loan_required: Optional[float] = None
    existing_loans: Optional[bool] = None
    existing_loan_amount: Optional[float] = None
    is_woman_entrepreneur: Optional[bool] = None
    disability_category: Optional[str] = None
    minority_category: Optional[str] = None
    ex_serviceman_status: Optional[bool] = None
