from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class SurveyQuestionInput(BaseModel):
    id: Optional[str] = None
    question_text: str
    question_type: str = Field(default="text", description="multiple_choice, numeric, scale, text, yes_no")
    options: List[str] = Field(default_factory=list)
    sort_order: int = 0


class SurveyCreate(BaseModel):
    research_project_id: str
    title: str
    target_respondent_type: str = "customer"
    questions: List[SurveyQuestionInput] = Field(default_factory=list)


class SurveyModelResponse(BaseModel):
    id: str
    research_project_id: str
    title: str
    target_respondent_type: str
    questions: List[SurveyQuestionInput] = Field(default_factory=list)
    created_at: datetime


class SurveyResponseCreate(BaseModel):
    survey_id: str
    respondent_identifier: Optional[str] = None
    answers: Dict[str, Any] = Field(default_factory=dict)
    extracted_claim: Optional[str] = None
    extracted_value: Optional[str] = None
    unit: Optional[str] = None
    collector_notes: Optional[str] = None


class SurveyResponseItem(BaseModel):
    id: str
    survey_id: str
    respondent_identifier: Optional[str] = None
    answers: Dict[str, Any]
    collector_notes: Optional[str] = None
    created_at: datetime
